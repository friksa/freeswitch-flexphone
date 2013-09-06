package {
	
	import flash.events.Event;

	public class ClientConnectedEvent extends Event{
        public static var TYPE:String = "ClientConnectedEvent";
        public function ClientConnectedEvent() {
			super(TYPE, false, false);
		}
	}
}