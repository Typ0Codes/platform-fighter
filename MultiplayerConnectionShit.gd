extends Node 

func _ready():
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	
	GDSync.start_multiplayer()
func connected():
	print("You are now connected!")
func connection_failed(error : int):
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			push_error("The public or private key you entered were invalid.")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			push_error("Unable to connect, please check your internet connection.")
