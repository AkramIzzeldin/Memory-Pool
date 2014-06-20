import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type.ClassField;

@:remove @:autobuild(ClonableImpl.clonableImpl) extern interface IClonable {}

typedef MyField = { f : Field, access:Array<String> }

class ClonableImpl
{
	macro public static function clonableImpl() : Array<Field>
	{
		var fields = Context.getBuildFields();
		
		var funcBody = [];
		
		var queue = new List<MyField>();
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
									funcBody.push(macro for (i in $p { field.access.concat( [field.f.name] ).concat( ["length"] ) } )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ) }[i] = $p { field.access.concat( [field.f.name] ) }[i] );
								case "Map":
									funcBody.push(macro for (key in $p { field.access.concat( [field.f.name] ).concat( ["keys"] ) }() )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ) }[key] = $p { field.access.concat( [field.f.name] ) }[key] );
								case "List":
									funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ).concat( ["clear"] ) }() );
									funcBody.push(macro for (item in $p { field.access.concat( [field.f.name] ).concat( ["iterator"] ) }() )
														$p { ["object"].concat( field.access ).concat( [field.f.name] ).concat( ["add"] ) } (item));
								case _:
									var type = Context.follow(Context.getType(p.sub == null ? p.name : p.name + '.' + p.sub));
									switch(type)
									{
										case TEnum (t, params):
											funcBody.push(macro $p { ["object"].concat( field.access ).concat( [field.f.name] ) } = $p { field.access.concat( [field.f.name] ) } );
										case TInst (t, params):
											// toField
										case TAnonymous (a):
											// toField
										case TAbstract (t, params):
											// extract field (this field with t.type as it's type)
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
			name : "CopyTo",
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
		
		trace(new Printer().printField(field));
		
		fields.push(field);
		
		return fields;
	}
	
	public function toField(cf : ClassField)
	{
		
	}
}
