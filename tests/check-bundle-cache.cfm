<cfscript>
/**
 * LDEV-5725 - Check Felix Bundle Cache for duplicate core bundles
 *
 * This script inspects the Felix cache to see if there are multiple
 * versions of the lucee.core bundle, which is the root cause of LDEV-5725.
 */

// Output to both console and HTTP response
out = function( msg ) {
	systemOutput( msg, true );
	echo( msg & chr( 10 ) );
};

out( "=" & repeatString( "=", 79 ) );
out( "LDEV-5725 Felix Bundle Cache Inspector" );
out( "=" & repeatString( "=", 79 ) );

out( "Lucee Version: " & server.lucee.version );
out( "" );

try {
	// Get the BundleContext
	engine = createObject( "java", "lucee.loader.engine.CFMLEngineFactory" ).getInstance();
	bc = engine.getBundleContext();

	out( "Installed Bundles:" );
	out( "-" & repeatString( "-", 79 ) );

	bundles = bc.getBundles();
	coreCount = 0;
	adminCount = 0;

	for ( b in bundles ) {
		symbolicName = b.getSymbolicName();
		version = b.getVersion().toString();
		state = b.getState();
		stateStr = "";

		switch ( state ) {
			case 1: stateStr = "UNINSTALLED"; break;
			case 2: stateStr = "INSTALLED"; break;
			case 4: stateStr = "RESOLVED"; break;
			case 8: stateStr = "STARTING"; break;
			case 16: stateStr = "STOPPING"; break;
			case 32: stateStr = "ACTIVE"; break;
			default: stateStr = "UNKNOWN(" & state & ")";
		}

		// Check for lucee.core bundles
		if ( symbolicName contains "lucee.core" || symbolicName contains "lucee-core" ) {
			coreCount++;
			out( "*** CORE: " & symbolicName & " v" & version & " [" & stateStr & "] - ID:" & b.getBundleId() );
			out( "    Location: " & b.getLocation() );
			out( "    ClassLoader: " & ( !isNull( b.adapt( createObject( "java", "org.osgi.framework.wiring.BundleWiring" ).getClass() ) ) ? b.adapt( createObject( "java", "org.osgi.framework.wiring.BundleWiring" ).getClass() ).getClassLoader().getClass().getName() : "N/A" ) );
		}

		// Check for admin/archive bundles
		if ( b.getLocation() contains "lucee-admin" || b.getLocation() contains ".lar" ) {
			adminCount++;
			out( "*** ARCHIVE: " & symbolicName & " v" & version & " [" & stateStr & "] - ID:" & b.getBundleId() );
			out( "    Location: " & b.getLocation() );
		}
	}

	out( "" );
	out( "=" & repeatString( "=", 79 ) );
	out( "Summary:" );
	out( "  Total bundles: " & arrayLen( bundles ) );
	out( "  Core bundles: " & coreCount );
	out( "  Archive bundles: " & adminCount );

	if ( coreCount > 1 ) {
		out( "" );
		out( "*** WARNING: Multiple core bundles detected! ***" );
		out( "This is the condition that causes LDEV-5725." );
		out( "Archive bundles may be wired to the wrong core version." );
	}

	// Now let's check the actual classloader situation
	out( "" );
	out( "=" & repeatString( "=", 79 ) );
	out( "ClassLoader Analysis:" );

	// Get ComponentPageImpl class from current context
	componentPageImplClass = createObject( "java", "lucee.runtime.ComponentPageImpl" ).getClass();
	out( "ComponentPageImpl loaded from: " & componentPageImplClass.getClassLoader().getClass().getName() );

	// Try to get admin mapping and check its classloader
	mappings = getPageContext().getConfig().getMappings();
	for ( m in mappings ) {
		archive = m.getStrArchive() ?: "";
		if ( archive.findNoCase( "lucee-admin" ) > 0 ) {
			out( "" );
			out( "Admin Mapping Archive ClassLoader Check:" );

			ps = m.getPageSource( "/Application.cfc" );
			page = ps.loadPage( getPageContext(), false );

			pageClassLoader = page.getClass().getClassLoader();
			cpiClassLoader = componentPageImplClass.getClassLoader();

			out( "  Page ClassLoader: " & pageClassLoader.getClass().getName() );
			out( "  ComponentPageImpl ClassLoader: " & cpiClassLoader.getClass().getName() );
			out( "  Same ClassLoader: " & ( pageClassLoader.equals( cpiClassLoader ) ) );

			// Check parent chain
			pageParent = page.getClass().getSuperclass();
			while ( !isNull( pageParent ) && pageParent.getName() != "java.lang.Object" ) {
				out( "  Parent: " & pageParent.getName() & " from " & pageParent.getClassLoader().getClass().getName() );
				pageParent = pageParent.getSuperclass();
			}

			break;
		}
	}

} catch ( any e ) {
	out( "" );
	out( "ERROR: " & e.message );
	out( e.stacktrace );
}

out( "" );
out( "=" & repeatString( "=", 79 ) );
out( "Check complete" );
out( "=" & repeatString( "=", 79 ) );
</cfscript>
