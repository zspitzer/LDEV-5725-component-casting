<cfscript>
/**
 * LDEV-5725 - Trigger Lucee restart
 */

systemOutput( "Triggering Lucee restart...", true );

try {
	admin = new Administrator( "server", "admin" );
	admin.restart();
	systemOutput( "Restart triggered", true );
} catch ( any e ) {
	// Expected - the restart will kill the current request
	systemOutput( "Restart initiated (connection likely dropped): " & e.message, true );
}
</cfscript>
