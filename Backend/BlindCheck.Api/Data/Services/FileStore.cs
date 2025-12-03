using System.Reflection;
using System.Text.Json;
using BlindCheck.Api.Data.Entities;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace BlindCheck.Api.Data.Services;

public class FileStore() : IStore
{
    private readonly Assembly _assembly = Assembly.GetExecutingAssembly();
    private readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly CosmosClient _cosmosClient;
    private readonly Container _container;
    private readonly ILogger<FileStore> _logger;

    public FileStore(ILogger<FileStore> logger, IConfiguration configuration) : this()
    {
        _logger = logger;
        // Customize this value based on desired DNS refresh timer
        // Registering the Singleton SocketsHttpHandler lets you reuse it across any HttpClient in your application
        var socketsHttpHandler = new SocketsHttpHandler
        {
            MaxConnectionsPerServer = 300,
            PooledConnectionLifetime = TimeSpan.FromHours(24),
            ConnectTimeout = TimeSpan.FromSeconds(60)
        };

        var cosmosClientOptions = new CosmosClientOptions
        {
            ConnectionMode = ConnectionMode.Gateway,
            SerializerOptions = new CosmosSerializationOptions
            {
                PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
            },
            HttpClientFactory = () =>
            {
                var client = new HttpClient(socketsHttpHandler, disposeHandler: false);
                return client;
            },
            ApplicationPreferredRegions = new List<string>
            {
                Regions.PolandCentral
            },
            AllowBulkExecution = true
        };
        _cosmosClient = new CosmosClient(configuration["CosmosDb:ConnectionString"], cosmosClientOptions);
        _container = _cosmosClient.GetContainer(
            configuration["CosmosDb:DatabaseName"],
            configuration["CosmosDb:ContainerName"]
        );
    }

    public async Task<BlindCheckForm?> GetBlindCheckFormByCaseIdAsync(string contractNumber)
    {
        var resourceName = $"{contractNumber}.json";

        // Get all embedded resource names to find the matching one
        var allResources = _assembly.GetManifestResourceNames();
        var matchingResource = allResources.FirstOrDefault(r => r.EndsWith(resourceName, StringComparison.OrdinalIgnoreCase));

        if (matchingResource == null)
        {
            _logger.LogInformation($"Could not find embedded resource for '{resourceName}'");
            return null;
        }

        await using var stream = _assembly.GetManifestResourceStream(matchingResource);
        if (stream == null)
        {
            throw new InvalidOperationException($"Could not load embedded resource stream for '{matchingResource}'");
        }

        var form = await JsonSerializer.DeserializeAsync<BlindCheckForm>(stream, _jsonOptions);

        return form ?? throw new InvalidOperationException($"Failed to deserialize BlindCheckForm from '{matchingResource}'");
    }

    public async Task<IEnumerable<BlindCheckForm>> GetAllBlindCheckFormsAsync()
    {
        var allResources = _assembly.GetManifestResourceNames();
        var jsonResources = allResources.Where(r => r.EndsWith(".json", StringComparison.OrdinalIgnoreCase)).ToList();

        var forms = new List<BlindCheckForm>();

        foreach (var resourceName in jsonResources)
        {
            try
            {
                await using var stream = _assembly.GetManifestResourceStream(resourceName);
                if (stream == null)
                {
                    _logger.LogWarning($"Could not load embedded resource stream for '{resourceName}'");
                    continue;
                }

                var form = await JsonSerializer.DeserializeAsync<BlindCheckForm>(stream, _jsonOptions);
                if (form != null)
                {
                    forms.Add(form);
                }
                else
                {
                    _logger.LogWarning($"Failed to deserialize BlindCheckForm from '{resourceName}'");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error loading embedded resource '{resourceName}'");
            }
        }

        return forms;
    }

    public async Task<BlindCheckForm?> GetBlindCheckFromFromDb(string caseId)
    {
        try
        {
            var response = await _container.ReadItemAsync<BlindCheckForm>(
                id: caseId,
                partitionKey: new PartitionKey(caseId)
            );

            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger?.LogInformation($"BlindCheckForm with caseId '{caseId}' not found in CosmosDB");
            return null;
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, $"Error retrieving BlindCheckForm with caseId '{caseId}' from CosmosDB");
            throw;
        }
    }

    public async Task<BlindCheckForm> SaveBlindCheckFormAsync(BlindCheckForm form)
    {
        try
        {
            var response = await _container.UpsertItemAsync(
                item: form,
                partitionKey: new PartitionKey("TODO")
            );

            _logger?.LogInformation($"Successfully saved BlindCheckForm with caseId '{"TODO"}' to CosmosDB");
            return response.Resource;
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, $"Error saving BlindCheckForm with caseId '{"TODO"}' to CosmosDB");
            throw;
        }
    }

    public async Task<int> SeedDatabaseFromEmbeddedFilesAsync()
    {
        try
        {
            var allResources = _assembly.GetManifestResourceNames();
            var jsonResources = allResources.Where(r => r.EndsWith(".json", StringComparison.OrdinalIgnoreCase)).ToList();

            _logger?.LogInformation($"Found {jsonResources.Count} embedded JSON files to seed");

            var savedCount = 0;
            var errors = new List<string>();

            foreach (var resourceName in jsonResources)
            {
                try
                {
                    await using var stream = _assembly.GetManifestResourceStream(resourceName);
                    if (stream == null)
                    {
                        _logger?.LogWarning($"Could not load stream for resource '{resourceName}'");
                        continue;
                    }

                    var form = await JsonSerializer.DeserializeAsync<BlindCheckForm>(stream, _jsonOptions);
                    if (form == null)
                    {
                        _logger?.LogWarning($"Failed to deserialize resource '{resourceName}'");
                        continue;
                    }

                    await SaveBlindCheckFormAsync(form);
                    savedCount++;
                    _logger?.LogInformation($"Seeded BlindCheckForm with caseId '{form.ContractNumber}' from '{resourceName}'");
                }
                catch (Exception ex)
                {
                    var errorMsg = $"Error processing resource '{resourceName}': {ex.Message}";
                    errors.Add(errorMsg);
                    _logger?.LogError(ex, errorMsg);
                }
            }

            _logger?.LogInformation($"Database seeding completed. Successfully saved {savedCount} out of {jsonResources.Count} forms");

            if (errors.Any())
            {
                _logger?.LogWarning($"Encountered {errors.Count} errors during seeding");
            }

            return savedCount;
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, "Fatal error during database seeding");
            throw;
        }
    }
}