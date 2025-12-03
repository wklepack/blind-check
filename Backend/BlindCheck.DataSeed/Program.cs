using BlindCheck.Api.Data.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Program_1 = Program;

Console.WriteLine("BlindCheck Data Seed Utility");
Console.WriteLine("============================");
Console.WriteLine();

var host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration((context, config) =>
    {
        config.SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddJsonFile($"appsettings.{context.HostingEnvironment.EnvironmentName}.json", optional: true, reloadOnChange: true)
            .AddUserSecrets<Program_1>()
            .AddEnvironmentVariables();
    })
    .ConfigureServices((context, services) =>
    {
        services.AddLogging(builder =>
        {
            builder.AddConsole();
            builder.SetMinimumLevel(LogLevel.Information);
        });
        services.AddSingleton(context.Configuration);
        services.AddSingleton<FileStore>();
    })
    .Build();

try
{
    var store = host.Services.GetRequiredService<FileStore>();

    Console.WriteLine("Starting database seeding from embedded files...");
    Console.WriteLine();

    var count = await store.SeedDatabaseFromEmbeddedFilesAsync();

    Console.WriteLine();
    Console.WriteLine($"✓ Database seeding completed successfully!");
    Console.WriteLine($"✓ Total forms seeded: {count}");
    Console.WriteLine();
}
catch (Exception ex)
{
    Console.WriteLine();
    Console.WriteLine($"✗ Error during database seeding: {ex.Message}");
    Console.WriteLine($"✗ Stack trace: {ex.StackTrace}");
    Console.WriteLine();
    return 1;
}

Console.WriteLine("Press any key to exit...");
Console.ReadKey();
return 0;
