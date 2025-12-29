<cfscript>
/**
 * LDEV-5725 - Trigger version change via Admin API
 *
 * This simulates clicking "downgrade" in the Lucee admin UI
 */

// Output to both console and HTTP response
out = function( msg ) {
	systemOutput( msg, true );
	echo( msg & chr( 10 ) );
};

out( "=" & repeatString( "=", 79 ) );
out( "LDEV-5725 - Admin API Version Change" );
out( "=" & repeatString( "=", 79 ) );

out( "Current Lucee Version: " & server.lucee.version );

// Get target version from URL parameter
targetVersion = url.version ?: "";
if ( targetVersion == "" ) {
	out( "ERROR: No version specified. Use ?version=x.x.x.xxx" );
	abort;
}

out( "Target Version: " & targetVersion );
out( "" );

// Get admin password from URL or use empty (for fresh installs)
adminPassword = url.password ?: "";

try {
	out( "Calling cfadmin action='changeVersionTo'..." );
	out( "This will trigger factory.restart() synchronously." );
	out( "" );

	admin
		action="changeVersionTo"
		type="server"
		password="#adminPassword#"
		version="#targetVersion#";

	// If we get here, the restart completed and we're on the new version
	out( "Version change completed!" );
	out( "New Lucee Version: " & server.lucee.version );

} catch ( any e ) {
	out( "" );
	out( "ERROR: " & e.message );
	out( e.detail ?: "" );
	out( "" );

	if ( e.message contains "casting" || e.message contains "ComponentPageImpl" ) {
		out( "*** LDEV-5725 REPRODUCED! ***" );
		out( "The casting error occurred during version change!" );
	}

	out( e.stacktrace );
}

out( "" );
out( "=" & repeatString( "=", 79 ) );
</cfscript>
