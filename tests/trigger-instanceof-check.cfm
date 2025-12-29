<cfscript>
/**
 * LDEV-5725 - Trigger the actual instanceof check that fails
 *
 * This simulates what ComponentLoader.initComponent() does:
 *   if (validate && !(page instanceof ComponentPageImpl))
 */

systemOutput( "=" & repeatString( "=", 79 ), true );
systemOutput( "LDEV-5725 - Direct instanceof Check", true );
systemOutput( "=" & repeatString( "=", 79 ), true );

systemOutput( "Lucee Version: " & server.lucee.version, true );
systemOutput( "", true );

try {
	// Find admin mapping
	mappings = getPageContext().getConfig().getMappings();
	for ( m in mappings ) {
		archive = m.getStrArchive() ?: "";
		if ( archive.findNoCase( "lucee-admin" ) > 0 ) {
			systemOutput( "Found admin mapping: " & m.getVirtual(), true );

			// Load the page
			ps = m.getPageSource( "/Application.cfc" );
			systemOutput( "PageSource: " & ps.getDisplayPath(), true );

			page = ps.loadPage( getPageContext(), false );
			systemOutput( "Page loaded: " & page.getClass().getName(), true );

			// Get the ComponentPageImpl class from the CURRENT runtime
			// This is what ComponentLoader does
			componentPageImplClass = createObject( "java", "lucee.runtime.ComponentPageImpl" ).getClass();

			systemOutput( "", true );
			systemOutput( "ClassLoader Comparison:", true );
			systemOutput( "  Page's ComponentPageImpl parent CL: " & page.getClass().getSuperclass().getClassLoader(), true );
			systemOutput( "  Current ComponentPageImpl CL: " & componentPageImplClass.getClassLoader(), true );

			// The actual instanceof check - this is what fails in ComponentLoader line 709
			systemOutput( "", true );
			systemOutput( "Performing instanceof check (same as ComponentLoader.java line 709)...", true );

			// Use Java reflection to do the exact same check
			isInstance = componentPageImplClass.isInstance( page );

			systemOutput( "  componentPageImplClass.isInstance(page) = " & isInstance, true );

			if ( !isInstance ) {
				systemOutput( "", true );
				systemOutput( "*** LDEV-5725 CONDITION DETECTED! ***", true );
				systemOutput( "The page is NOT an instance of the current ComponentPageImpl!", true );
				systemOutput( "This is exactly what causes the casting error.", true );
				systemOutput( "", true );
				systemOutput( "In ComponentLoader.initComponent(), this would throw:", true );
				systemOutput( '"there is a problem with casting [' & ps.getDisplayPath() & '] to a component (ComponentPageImpl)"', true );

				// Show the classloader mismatch details
				systemOutput( "", true );
				systemOutput( "ClassLoader Mismatch Details:", true );

				pageCL = page.getClass().getSuperclass().getClassLoader();
				currentCL = componentPageImplClass.getClassLoader();

				systemOutput( "  Page's CL identity: " & pageCL.hashCode(), true );
				systemOutput( "  Current CL identity: " & currentCL.hashCode(), true );

				// Check if they're both BundleClassLoaders for different bundles
				if ( pageCL.getClass().getName() contains "BundleClassLoader" ) {
					try {
						// Try to get bundle info
						bundleWiring = pageCL.getClass().getMethod( "getBundle", [] ).invoke( pageCL, [] );
						systemOutput( "  Page's bundle: " & bundleWiring.getSymbolicName() & " v" & bundleWiring.getVersion(), true );
					} catch ( any e ) {
						// Ignore - just trying to get extra info
					}
				}
			} else {
				systemOutput( "", true );
				systemOutput( "instanceof check PASSED - no bug condition.", true );
				systemOutput( "The page is properly an instance of the current ComponentPageImpl.", true );
			}

			break;
		}
	}

} catch ( any e ) {
	systemOutput( "", true );
	systemOutput( "ERROR: " & e.message, true );
	systemOutput( e.detail ?: "", true );
	systemOutput( "", true );

	if ( e.message contains "casting" || e.message contains "ComponentPageImpl" ) {
		systemOutput( "*** LDEV-5725 REPRODUCED VIA EXCEPTION! ***", true );
	}

	systemOutput( e.stacktrace, true );
}

systemOutput( "", true );
systemOutput( "=" & repeatString( "=", 79 ), true );
</cfscript>
