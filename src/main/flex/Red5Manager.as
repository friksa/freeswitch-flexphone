package {
	
	import com.adobe.crypto.MD5;
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.*;
	import flash.net.NetConnection;
	import flash.net.NetStream;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
	
	public class Red5Manager {
			
		[Bindable]
		public  var netConnection:NetConnection = null;
		private var incomingNetStream:NetStream = null;
		private var outgoingNetStream:NetStream = null;
		private var uid:String;
		private var connectUrls:Vector.<Array>;

		private var isConnected:Boolean = false;
		private var isInCall:Boolean = false;

        private var connectionTimer:Timer;

        public var callerNumber:String = "000";

		public function Red5Manager() {
			this.init();
		}
		
		private function init():void {
			
			NetConnection.defaultObjectEncoding = flash.net.ObjectEncoding.AMF0;	
			netConnection = new NetConnection();
			netConnection.client = this;
            netConnection.proxyType = "none";
			netConnection.addEventListener( NetStatusEvent.NET_STATUS , netStatus );
			netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}

        private function log(message:String):void
        {
            trace (message);
            if (ExternalInterface.available)
            {
                ExternalInterface.call('console.log', message);
            }
        }


        public function connectRed5(urls:Vector.<Array>):void {
            connectUrls = urls;
            connectionTimer = new Timer(1000);
            connectionTimer.addEventListener('timer', onConnectionTimer);
            connectionTimer.start();
            tryConnect();
		}

        public function onConnectionTimer(e:TimerEvent):void{
            tryConnect();
        }
		public function closeNetConnection():void {
            log("Close connection");
			netConnection.close();
		}

		private function netStatus (evt:NetStatusEvent ):void {
            log(evt.info.code);
            switch(evt.info.code) {
                case "NetConnection.Connect.Success":
                    isConnected = true;
                    if(connectionTimer != null){
                        connectionTimer.stop();
                    }
                    dispatchEvent(new ClientConnectedEvent());
                    break;

                case "NetConnection.Connect.Failed":
                    if(isConnected){
                        //Verspaetete Meldung von vorherigen Versuch
                        return;
                    }
                    if(tryConnect()){
                        return;
                    }
                    dispatchEvent(new ClientConnectionFailedEvent());
                    break;

                case "NetConnection.Connect.Closed":
                    if(isConnected){
                        dispatchEvent(new ClientDisconnectedEvent());
                    }
                    isConnected = false;
                    break;

                case "NetConnection.Connect.Rejected":
                    dispatchEvent(new ClientConnectionFailedEvent());
                    break;

                case "NetStream.Play.StreamNotFound":
                    break;

                case "NetStream.Play.Failed":
                    break;

                case "NetStream.Play.Start":
                    break;

                case "NetStream.Play.Stop":
                    break;

                case "NetStream.Buffer.Full":
                    break;

                default:

            }
        }

        private function tryConnect():Boolean {
            try{
                if(connectUrls == null || connectUrls.length < 1){
                    if(connectionTimer != null){
                        connectionTimer.stop();
                    }
                    return false;
                }
                if(netConnection != null){
                    netConnection.close();
                }
                var url:Array = connectUrls.shift();
                log("Connecting to "+url[1]+ " with proxy type "+url[0]);
                init();//NetConnection reinitialisieren
                netConnection.proxyType = url[0];
                netConnection.connect(url[1]);
                return true;
            }catch(error:Error){
                log(error.toString()) ;
                log(error.getStackTrace());
            }
            return false;
        }

		private function asyncErrorHandler(event:AsyncErrorEvent):void {
            log("AsyncErrorEvent: " + event);
           trace("AsyncErrorEvent: " + event);
        }
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
            log("securityErrorHandler: " + event);
            trace("securityErrorHandler: " + event);
        }
        
     
        
        //********************************************************************************************
		//			
		//			CallBack Methods from Red5 
		//
		//********************************************************************************************

        public function onMakeCall(uuid:String, number:String, account:String):void {
            log("onMakeCall "+uuid+" "+number);
        }

        public function onHangup(uuid:String, cause:String):void {
            log("onHangUp "+uuid+" "+cause);
            dispatchEvent (new CallDisconnectedEvent(CallDisconnectedEvent.DISCONNECTED,  cause));
            isInCall = false;
        }

        public function callState(uuid:String, msg:String):void {
            log("callState "+uuid+" "+msg);
            dispatchEvent (new Red5MessageEvent(Red5MessageEvent.MESSAGE, Red5MessageEvent.CALLSTATE,  msg));
			if(!isInCall && msg == "ACTIVE"){
                dispatchEvent (new CallConnectedEvent(CallConnectedEvent.CONNECTED, uuid,  ""));
                uid = uuid;
                isInCall = true;
            }
		}
		
		public function incoming(source:String, sourceName:String, destination:String, destinationName:String):*  {		
			dispatchEvent (new IncomingCallEvent(IncomingCallEvent.INCOMING, source,  sourceName, destination, destinationName ));
		}
        
        public function connected(suid:String):* {
            log("Session connected: "+suid);
		}

		//********************************************************************************************
		//			
		//			SIP Actions
		//
		//********************************************************************************************
		
		public function doCall(dialStr:String):void {
            netConnection.call("makeCall", null, dialStr, "", {SignallingNumber:callerNumber});
			//netConnection.call("call", null, uid, dialStr);
		}

		public function doCallChar(chr:String):void {
			if (isInCall) {
                netConnection.call("sendDTMF", null, chr, 600);
				//netConnection.call("dtmf", null, uid, chr);
			}
		}
		
		public function doHangUp():void {
            if(uid != null){
			    netConnection.call("hangup", null, uid);
            }
		}
		
	}
}