package;

/**
 * ...
 * @author AkramIzzeldin
 * Copyright 2014 Akram Izzeldin

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */

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
