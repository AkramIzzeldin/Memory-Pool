import Type;

class Pool<A>
{
    public function new (allocator :Void -> A)
    {
        _allocator = allocator;
        _newObject = _allocator();
        _freeObjects = [];
    }
    
    public function take (doInit:Bool = false) :A
    {
        if (_freeObjects.length > 0) {
            return doInit?init(_freeObjects.pop()):_freeObjects.pop();
        }
        var object = _allocator();
        return object;
    }
    
    public function put (object :A)
    {
            _freeObjects.push(object);
    }
    
    public function init(object :A):A
    {
        object = Copy.copy(_newObject);
        return object;
    }

    private var _allocator :Void -> A;
    private var _freeObjects :Array<A>;
    private var _newObject:A;
    private var _fields:Array<String>;
}


class Copy 
{
	public static function copy<T>( v:T ) : T  
	{
		var vType:ValueType = Type.typeof(v);
		
		switch(vType)
		{
			case TNull | TInt | TFloat | TBool:
				return v;
			case TFunction:
				return null;
			case _:
		}
		
		var cType = Type.getClass(v);
		
		if (cType != null)
		{
			var sType = Type.getClassName(Type.getClass(v));
			switch(sType)
			{
				case "String":
					return v;
				case "Array":
					var result = Type.createInstance(Type.getClass(v), []); 
					untyped 
						for ( ii in 0...v.length ) 
							result.push(copy(v[ii]));
					return result;
				case "Map":
					var result = Type.createInstance(Type.getClass(v), []);
					untyped 
					{
						var keys = v.keys();
						for ( key in [while (keys.hasNext) keys.next] ) 
						result.set(key, copy(v.get(key)));
					} 
					return result;
				case "List":
					var result = Type.createInstance(Type.getClass(v), []);
					untyped 
					{
						var iter : Iterator<Dynamic> = v.iterator();
						for ( ii in iter ) 
						{
							result.add(ii);
						}
					} 
					return result;
				case _:
					var obj : Dynamic = {}; 
					for ( ff in Reflect.fields(v) )
						Reflect.setField(obj, ff, copy(Reflect.field(v, ff))); 
					return obj; 
			}
		}
		else
		{
			var obj : Dynamic = {}; 
			for ( ff in Reflect.fields(v) ) 
			{ 
				Reflect.setField(obj, ff, copy(Reflect.field(v, ff))); 
			}
			return obj;
		}
		return null;
	}
}

class Main
{
	static public function main()
	{
		var pool = new Pool(function() { return {x:0, y:0}; } );
		{
			var p1 = pool.take();
			var p2 = pool.take();
			
			p1.x = p1.y = 1;
			p2.x = p2.y = 1;
			
			pool.put(p1);
			pool.put(p2);
		}
		var p1 = pool.take(true);
		var p2 = pool.take();
		
		trace(p1);
		trace(p2);
		
		Sys.stdin().readLine();
	}
}
