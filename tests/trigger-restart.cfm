<cfscript>
/**
 * LDEV-5725 - Trigger Lucee hot restart
 *
 * This triggers a hot restart (engine reload without JVM restart)
 * which is the scenario where the bug manifests.
 */

systemOutput( "Triggering Lucee hot restart...", true );

try {
	// Get the engine factory directly - no password needed
	engine = createObject( "java", "lucee.loader.engine.CFMLEngineFactory" ).getInstance();
	factory = engine.getCFMLEngineFactory();

	systemOutput( "Current version before restart: " & server.lucee.version, true );

	// Trigger the restart
	factory.restart( "" ); // Empty password works for internal calls

	systemOutput( "Restart triggered", true );
} catch ( any e ) {
	// Expected - the restart will kill the current request
	systemOutput( "Restart initiated (error expected): " & e.message, true );
	systemOutput( e.type, true );
}
</cfscript>
