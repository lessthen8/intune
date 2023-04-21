if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

get-appxpackage -allusers *xbox* 				| remove-appxpackage
get-appxpackage -allusers *bing* 				| remove-appxpackage
get-appxpackage -allusers *sway* 				| remove-appxpackage
get-appxpackage -allusers *people* 				| remove-appxpackage
get-appxpackage -allusers *solitaire* 			| remove-appxpackage
get-appxpackage -allusers *messaging* 			| remove-appxpackage
get-appxpackage -allusers *zune* 				| remove-appxpackage
get-appxpackage -allusers *officehub* 			| remove-appxpackage
get-appxpackage -allusers *communicationsapps* 	| remove-appxpackage
get-appxpackage -allusers *onenote* 			| remove-appxpackage
get-appxpackage -allusers *phone* 				| remove-appxpackage
get-appxpackage -allusers *skype* 				| remove-appxpackage

get-appxpackage -allusers *networkspeedtest* 	| remove-appxpackage
get-appxpackage -allusers *whiteboard* 			| remove-appxpackage
get-appxpackage -allusers *todos* 				| remove-appxpackage
get-appxpackage -allusers *remotedesktop* 		| remove-appxpackage
get-appxpackage -allusers *lens* 				| remove-appxpackage
get-appxpackage -allusers *oneconnect* 			| remove-appxpackage
get-appxpackage -allusers *camera* 				| remove-appxpackage
get-appxpackage -allusers *getstarted* 			| remove-appxpackage
get-appxpackage -allusers *skypeapp* 			| remove-appxpackage
get-appxpackage -allusers *zune* 				| remove-appxpackage
get-appxpackage -allusers *music* 				| remove-appxpackage
get-appxpackage -allusers *wallet* 				| remove-appxpackage
get-appxpackage -allusers *whiteboard* 			| remove-appxpackage
get-appxpackage -allusers *maps* 				| remove-appxpackage
get-appxpackage -allusers *photos* 				| remove-appxpackage
get-appxpackage -allusers *stickynotes* 		| remove-appxpackage
get-appxpackage -allusers *bing* 				| remove-appxpackage
get-appxpackage -allusers *record* 				| remove-appxpackage

#get-appxpackage -allusers ** | remove-appxpackage


