import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;
#if debug
import haxe.macro.Printer;
#end
@:remove @:autoBuild(ClonableImpl.build()) extern interface IClonable {	}

class ClonableImpl
{
	macro public static function build() : Array<Field>
	{
		var fields = Context.getBuildFields();
		
		var funcBody = [];
		
		var queue = new List<{f: Field, access:Array<String>}>();
		for (field in fields)
			queue.add( { f: field, access: [] } );
		
		while (!queue.isEmpty())
		{
			var field = queue.pop();
			switch(field.f.kind)
			{
				case FVar(cType, e) | FProp(_, _, cType, e):
					if (cType == null)
					{
						var typedExpr = Context.typeExpr(e);
						cType = Context.toComplexType(typedExpr.t);
					}
					switch(cType)
					{
						case TPath (p):
							switch(p.sub == null ? p.name : p.sub)
							{
								case "Int" | "Float" | "Bool" | "String":
									funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ) } = $p { field.access.concat( [field.f.name] ) } );
								case "Array" | "Vector":
									funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ) } = []);
									funcBody.push(macro for (i in 0 ... $p { field.access.concat( [field.f.name] ).concat( ["length"] ) } )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ) }[i] = $p { field.access.concat( [field.f.name] ) }[i] );
								case "Map":
									funcBody.push(macro for (key in $p { [ "object"].concat( field.access ).concat( [field.f.name] ).concat( ["keys"] ) } () )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ).concat( ["remove"] ) }(key));
									funcBody.push(macro for (key in $p { field.access.concat( [field.f.name] ).concat( ["keys"] ) }() )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ) }[key] = $p { field.access.concat( [field.f.name] ) }[key] );
								case "List":
									funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ).concat( ["clear"] ) }() );
									funcBody.push(macro for (item in $p { field.access.concat( [field.f.name] ).concat( ["iterator"] ) }() )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ).concat( ["add"] ) } (item));
								case _:
									var type = Context.follow(Context.getType(p.sub == null ? p.name : p.name + '.' + p.sub));
									var isAbstract = true;
									while (isAbstract)
									{
										switch(type)
										{
											case TAbstract(t, params):
												type = t.get().type;
												switch(t.get().name)
												{
													case "Int" | "Float" | "Bool":
														isAbstract = false;
														switch(field.f.kind)
														{
															case FVar(ct, expr):
																field.f.kind = FVar(Context.toComplexType(type), expr);
																queue.push( { f : field.f, access : field.access } );
															case _:
														}
													case _:
												}
											case _:
												isAbstract = false;
										}
									}
									switch(type)
									{
										case TEnum (t, params):
											funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ) } = $p { field.access.concat( [field.f.name] ) } );
										case TInst (t, params):
											var fs = t.get().fields.get();
											var superClass = t.get().superClass;
											while (superClass != null)
											{
												for (fi in t.get().superClass.t.get().fields.get())
													fs.push(fi);
												superClass = superClass.t.get().superClass;
											}
											for (fi in fs)
												switch(fi.kind)
												{
													case FVar(_, _):
														queue.push ( { f : toField(fi), access : field.access.concat( [field.f.name] ) } );
													case _:
												}
										case TAnonymous (a):
											for (fi in a.get().fields)
											{
												switch(fi.kind)
												{
													case FVar(_, _):
														queue.push ( { f : toField(fi), access : field.access.concat( [field.f.name] ) } );
													case _:
												}
											}
										case _:
								}
							}
						case TFunction (args, ret):
							funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ) } = $p { field.access.concat( [field.f.name] ) } );
						case TAnonymous (fs):
							for (fi in fs)
								queue.push( { f : fi, access : field.access.concat( [field.f.name] ) } );
						case _:
					}
				case FFun(_):
			}
		}
		
		var field = {
			name : "copyTo",
			pos : Context.currentPos(),
			access : [Access.APublic],
			meta : [],
			doc : null,
			kind : FieldType.FFun ( {
				args : [ {
					type : Context.toComplexType(Context.getLocalType()),
					name : "object"
				} ],
				ret : null,
				params : [],
				expr : macro $b{funcBody}
			} )
		};
		
		fields.push(field);
		
		#if debug
		trace(new Printer().printField(field));
		#end
		
		return fields;
	}
	
	static public function toField(cf : ClassField) : Field
	{
		var fieldAccess = [];
		cf.isPublic ? fieldAccess.push(APublic) : fieldAccess.push(APrivate);
		
		var cType = Context.toComplexType(cf.type);
		
		var expr;
		cf.expr() != null ?
		expr = Context.getTypedExpr(cf.expr()) :
		expr = null;
		
		var fieldKind = FVar(cType, expr);
		return {
			pos : cf.pos,
			name : cf.name,
			meta : cf.meta.get(),
			doc : cf.doc,
			access : fieldAccess,
			kind : fieldKind
		}
	}
}
