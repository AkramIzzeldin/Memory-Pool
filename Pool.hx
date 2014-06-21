class Pool<T>
{
    public function new (allocator:Void -> T)
    {
        _allocator = allocator;
        _newObject = _allocator();
        _freeObjects = [];
    }
    
    public function take (doInit:Bool = false) : T
    {
        if (_freeObjects.length > 0) {
            return doInit?init(_freeObjects.pop()):_freeObjects.pop();
        }
        var object = _allocator();
        return object;
    }
    
    public function put (object : T)
    {
            _freeObjects.push(object);
    }
    
    public function init(object:T) : T
    {
        untyped _newObject.copyTo(object);
        return object;
    }

    private var _allocator : Void -> T;
    private var _freeObjects : Array<T>;
    private var _newObject : T;
}
