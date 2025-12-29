<cfscript>
/**
 * LDEV-5725 - Check Felix Bundle Cache for duplicate core bundles
 *
 * This script inspects the Felix cache to see if there are multiple
 * versions of the lucee.core bundle, which is the root cause of LDEV-5725.
 */

systemOutput( "=" & repeatString( "=", 79 ), true );
systemOutput( "LDEV-5725 Felix Bundle Cache Inspector", true );
systemOutput( "=" & repeatString( "=", 79 ), true );

systemOutput( "Lucee Version: " & server.lucee.version, true );
systemOutput( "", true );

try {
	// Get the BundleContext
	engine = createObject( "java", "lucee.loader.engine.CFMLEngineFactory" ).getInstance();
	bc = engine.getBundleContext();

	systemOutput( "Installed Bundles:", true );
	systemOutput( "-" & repeatString( "-", 79 ), true );

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
			systemOutput( "*** CORE: " & symbolicName & " v" & version & " [" & stateStr & "] - ID:" & b.getBundleId(), true );
			systemOutput( "    Location: " & b.getLocation(), true );
			systemOutput( "    ClassLoader: " & ( !isNull( b.adapt( createObject( "java", "org.osgi.framework.wiring.BundleWiring" ).getClass() ) ) ? b.adapt( createObject( "java", "org.osgi.framework.wiring.BundleWiring" ).getClass() ).getClassLoader().getClass().getName() : "N/A" ), true );
		}

		// Check for admin/archive bundles
		if ( b.getLocation() contains "lucee-admin" || b.getLocation() contains ".lar" ) {
			adminCount++;
			systemOutput( "*** ARCHIVE: " & symbolicName & " v" & version & " [" & stateStr & "] - ID:" & b.getBundleId(), true );
			systemOutput( "    Location: " & b.getLocation(), true );
		}
	}

	systemOutput( "", true );
	systemOutput( "=" & repeatString( "=", 79 ), true );
	systemOutput( "Summary:", true );
	systemOutput( "  Total bundles: " & arrayLen( bundles ), true );
	systemOutput( "  Core bundles: " & coreCount, true );
	systemOutput( "  Archive bundles: " & adminCount, true );

	if ( coreCount > 1 ) {
		systemOutput( "", true );
		systemOutput( "*** WARNING: Multiple core bundles detected! ***", true );
		systemOutput( "This is the condition that causes LDEV-5725.", true );
		systemOutput( "Archive bundles may be wired to the wrong core version.", true );
	}

	// Now let's check the actual classloader situation
	systemOutput( "", true );
	systemOutput( "=" & repeatString( "=", 79 ), true );
	systemOutput( "ClassLoader Analysis:", true );

	// Get ComponentPageImpl class from current context
	componentPageImplClass = createObject( "java", "lucee.runtime.ComponentPageImpl" ).getClass();
	systemOutput( "ComponentPageImpl loaded from: " & componentPageImplClass.getClassLoader().getClass().getName(), true );

	// Try to get admin mapping and check its classloader
	mappings = getPageContext().getConfig().getMappings();
	for ( m in mappings ) {
		archive = m.getStrArchive() ?: "";
		if ( archive.findNoCase( "lucee-admin" ) > 0 ) {
			systemOutput( "", true );
			systemOutput( "Admin Mapping Archive ClassLoader Check:", true );

			ps = m.getPageSource( "/Application.cfc" );
			page = ps.loadPage( getPageContext(), false );

			pageClassLoader = page.getClass().getClassLoader();
			cpiClassLoader = componentPageImplClass.getClassLoader();

			systemOutput( "  Page ClassLoader: " & pageClassLoader.getClass().getName(), true );
			systemOutput( "  ComponentPageImpl ClassLoader: " & cpiClassLoader.getClass().getName(), true );
			systemOutput( "  Same ClassLoader: " & ( pageClassLoader.equals( cpiClassLoader ) ), true );

			// Check parent chain
			pageParent = page.getClass().getSuperclass();
			while ( !isNull( pageParent ) && pageParent.getName() != "java.lang.Object" ) {
				systemOutput( "  Parent: " & pageParent.getName() & " from " & pageParent.getClassLoader().getClass().getName(), true );
				pageParent = pageParent.getSuperclass();
			}

			break;
		}
	}

} catch ( any e ) {
	systemOutput( "", true );
	systemOutput( "ERROR: " & e.message, true );
	systemOutput( e.stacktrace, true );
}

systemOutput( "", true );
systemOutput( "=" & repeatString( "=", 79 ), true );
systemOutput( "Check complete", true );
systemOutput( "=" & repeatString( "=", 79 ), true );
</cfscript>
