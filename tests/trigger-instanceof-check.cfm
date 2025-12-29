<cfscript>
/**
 * LDEV-5725 - Trigger the actual instanceof check that fails
 *
 * This simulates what ComponentLoader.initComponent() does:
 *   if (validate && !(page instanceof ComponentPageImpl))
 */

// Output to both console and HTTP response
out = function( msg ) {
	systemOutput( msg, true );
	echo( msg & chr( 10 ) );
};

out( "=" & repeatString( "=", 79 ) );
out( "LDEV-5725 - Direct instanceof Check" );
out( "=" & repeatString( "=", 79 ) );

out( "Lucee Version: " & server.lucee.version );
out( "" );

try {
	// Find admin mapping
	mappings = getPageContext().getConfig().getMappings();
	for ( m in mappings ) {
		archive = m.getStrArchive() ?: "";
		if ( archive.findNoCase( "lucee-admin" ) > 0 ) {
			out( "Found admin mapping: " & m.getVirtual() );

			// Load the page
			ps = m.getPageSource( "/Application.cfc" );
			out( "PageSource: " & ps.getDisplayPath() );

			page = ps.loadPage( getPageContext(), false );
			out( "Page loaded: " & page.getClass().getName() );

			// Get the ComponentPageImpl class from the CURRENT runtime
			// This is what ComponentLoader does
			componentPageImplClass = createObject( "java", "lucee.runtime.ComponentPageImpl" ).getClass();

			out( "" );
			out( "ClassLoader Comparison:" );
			out( "  Page's ComponentPageImpl parent CL: " & page.getClass().getSuperclass().getClassLoader() );
			out( "  Current ComponentPageImpl CL: " & componentPageImplClass.getClassLoader() );

			// The actual instanceof check - this is what fails in ComponentLoader line 709
			out( "" );
			out( "Performing instanceof check (same as ComponentLoader.java line 709)..." );

			// Use Java reflection to do the exact same check
			isInstance = componentPageImplClass.isInstance( page );

			out( "  componentPageImplClass.isInstance(page) = " & isInstance );

			if ( !isInstance ) {
				out( "" );
				out( "*** LDEV-5725 CONDITION DETECTED! ***" );
				out( "The page is NOT an instance of the current ComponentPageImpl!" );
				out( "This is exactly what causes the casting error." );
				out( "" );
				out( "In ComponentLoader.initComponent(), this would throw:" );
				out( '"there is a problem with casting [' & ps.getDisplayPath() & '] to a component (ComponentPageImpl)"' );

				// Show the classloader mismatch details
				out( "" );
				out( "ClassLoader Mismatch Details:" );

				pageCL = page.getClass().getSuperclass().getClassLoader();
				currentCL = componentPageImplClass.getClassLoader();

				out( "  Page's CL identity: " & pageCL.hashCode() );
				out( "  Current CL identity: " & currentCL.hashCode() );

				// Check if they're both BundleClassLoaders for different bundles
				if ( pageCL.getClass().getName() contains "BundleClassLoader" ) {
					try {
						// Try to get bundle info
						bundleWiring = pageCL.getClass().getMethod( "getBundle", [] ).invoke( pageCL, [] );
						out( "  Page's bundle: " & bundleWiring.getSymbolicName() & " v" & bundleWiring.getVersion() );
					} catch ( any e ) {
						// Ignore - just trying to get extra info
					}
				}
			} else {
				out( "" );
				out( "instanceof check PASSED - no bug condition." );
				out( "The page is properly an instance of the current ComponentPageImpl." );
			}

			break;
		}
	}

} catch ( any e ) {
	out( "" );
	out( "ERROR: " & e.message );
	out( e.detail ?: "" );
	out( "" );

	if ( e.message contains "casting" || e.message contains "ComponentPageImpl" ) {
		out( "*** LDEV-5725 REPRODUCED VIA EXCEPTION! ***" );
	}

	out( e.stacktrace );
}

out( "" );
out( "=" & repeatString( "=", 79 ) );
</cfscript>
