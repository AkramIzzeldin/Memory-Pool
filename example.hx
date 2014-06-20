package;

import Pool;

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
		
		var p1 = pool.take(true); // this var will be initialized
		var p2 = pool.take(); // this var won't be initialized
		
		trace(p1);
		trace(p2);
	}
}
