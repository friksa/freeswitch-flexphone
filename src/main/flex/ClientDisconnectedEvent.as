package {

import flash.events.Event;

public class ClientDisconnectedEvent extends Event {
    public static var TYPE:String = "ClientDisconnectedEvent";

    public function ClientDisconnectedEvent() {
        super(TYPE, false, false);
    }
}
}