package city.analysis;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * Main entry point for the CityAnalysis module.
 * Run from IDE or terminal: java CityAnalysisMain [cityName] [inputFile]
 */
public class CityAnalysisMain
{
    public static void main(String[] args)
    {
        System.out.println("-- : [CityAnalysisMain] . CityAnalysis™ now starting .");

        // Start the city analysis server
        city_analysis.CityAnalysisServer server = new city_analysis.CityAnalysisServer();

        if (args.length > 0)
        {
            server.selectCity(args[0]);
        }

        System.out.println("-- : [CityAnalysisMain] Active city: " + server.getSelectedCity());

        // If an input file is provided, run the speculation engine
        if (args.length > 1)
        {
            city_analysis.CitySpeculationEngine engine = new city_analysis.CitySpeculationEngine(args[1]);
            engine.speculateRecursively();
            engine.writeResults();
        }
        else
        {
            // Default: fetch data for selected city
            server.fetchDeedsSearch();
            server.fetchPropertyRecords();
        }

        System.out.println("-- : [CityAnalysisMain] . CityAnalysis™ complete .");
    }
}
