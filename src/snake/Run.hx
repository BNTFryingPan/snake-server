package snake;

import hxargs.Args;
import snake.http.BaseHTTPRequestHandler;
import snake.http.HTTPServer;
import snake.http.SimpleHTTPRequestHandler;
import snake.socket.BaseRequestHandler;
import sys.net.Host;
import sys.net.Socket;

class Run {
	private static final DEFAULT_PROTOCOL = "HTTP/1.0";
	private static final DEFAULT_ADDRESS = "127.0.0.1";
	private static final DEFAULT_PORT = 8000;

	public static function main():Void {
		var args = Sys.args();
		if (Sys.getEnv("HAXELIB_RUN") == "1" && Sys.getEnv("HAXELIB_RUN_NAME") == "snake-server") {
			var cwd = args.pop();
			Sys.setCwd(cwd);
		}

		var address:String = DEFAULT_ADDRESS;
		var port:Int = DEFAULT_PORT;
		var directory:String = null;
		var protocol:String = DEFAULT_PROTOCOL;
		var argHandler = Args.generate([
			@doc('bind to this address (default: ${DEFAULT_ADDRESS})')
			["--bind"] => function(host:String) {
				address = host;
			},
			@doc('serve this directory (default: current directory)')
			["--directory"] => function(path:String) {
				directory = path;
			},
			@doc('conform to this HTTP version (default: ${DEFAULT_PROTOCOL})')
			["--protocol"] => function(version:String) {
				protocol = version;
			},
			@doc('bind to this port (default: ${DEFAULT_PORT})')
			["--port"] => function(tcpPort:Int) {
				port = tcpPort;
			},
		]);
		argHandler.parse(args);
		BaseHTTPRequestHandler.protocolVersion = protocol;
		var httpServer = new RunHTTPServer(new Host(address), port, SimpleHTTPRequestHandler, directory);
		httpServer.serveForever();
	}
}

private class RunHTTPServer extends HTTPServer {
	private var directory:String;

	public function new(serverHost:Host, serverPort:Int, requestHandlerClass:Class<BaseRequestHandler>, bindAndActivate:Bool = true, ?protocolVersion:String,
			?directory:String) {
		this.directory = directory;
		super(serverHost, serverPort, requestHandlerClass, bindAndActivate);
		Sys.print('Serving HTTP on ${serverAddress.host} port ${serverAddress.port} (http://${serverAddress.host}:${serverAddress.port})\n');
	}

	override private function finishRequest(request:Socket, clientAddress:{host:Host, port:Int}):Void {
		Type.createInstance(requestHandlerClass, [request, clientAddress, this, directory]);
	}
}
