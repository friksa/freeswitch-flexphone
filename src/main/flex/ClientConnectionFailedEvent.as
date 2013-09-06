package {
	
	import flash.events.Event;

	public class ClientConnectionFailedEvent extends Event{
        public static var TYPE:String = "ClientConnectionFailedEvent";
        public function ClientConnectionFailedEvent() {
			super(TYPE, false, false);
		}
	}
}