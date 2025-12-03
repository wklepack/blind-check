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

    public async Task<bool> UpdateBlindCheckVerificationAsync(string contractNumber, bool isVerified, string userName)
    {
        try
        {
            // Get the existing form from CosmosDB
            var form = await GetBlindCheckFromFromDbAsync(contractNumber);

            if (form == null)
            {
                _logger.LogWarning($"BlindCheckForm with contract number '{contractNumber}' not found for verification update");
                return false;
            }

            // Update the verification status
            form.BlindCheckVerification.IsVerified = isVerified;
            form.BlindCheckVerification.VerifiedBy = userName;
            form.BlindCheckVerification.VerifiedAt = DateTime.UtcNow;

            // Save the updated form back to CosmosDB
            await _container.UpsertItemAsync(
                item: form,
                partitionKey: new PartitionKey(contractNumber)
            );

            _logger.LogInformation($"Successfully updated verification status for BlindCheckForm with contract number '{contractNumber}' to {isVerified}");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error updating verification status for BlindCheckForm with contract number '{contractNumber}'");
            throw new InvalidOperationException($"Failed to update verification status for contract number '{contractNumber}'", ex);
        }
    }

    public async Task<BlindCheckForm?> GetBlindCheckFromFromDbAsync(string contractNumber)
    {
        try
        {
            var response = await _container.ReadItemAsync<BlindCheckForm>(
                id: contractNumber,
                partitionKey: new PartitionKey(contractNumber)
            );

            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger?.LogInformation($"BlindCheckForm with caseId '{contractNumber}' not found in CosmosDB");
            return null;
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, $"Error retrieving BlindCheckForm with caseId '{contractNumber}' from CosmosDB");
            throw;
        }
    }

    public async Task<IEnumerable<BlindCheckForm>> GetAllBlindCheckFormsFromDbAsync()
    {
        try
        {
            var query = _container.GetItemQueryIterator<BlindCheckForm>(
                new QueryDefinition("SELECT * FROM c")
            );

            var forms = new List<BlindCheckForm>();

            while (query.HasMoreResults)
            {
                var response = await query.ReadNextAsync();
                forms.AddRange(response);
            }

            _logger?.LogInformation($"Successfully retrieved {forms.Count} BlindCheckForms from CosmosDB");
            return forms;
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, "Error retrieving all BlindCheckForms from CosmosDB");
            throw;
        }
    }

    public async Task<BlindCheckForm> SaveBlindCheckFormAsync(BlindCheckForm form)
    {
        try
        {
            var response = await _container.UpsertItemAsync(
                item: form,
                partitionKey: new PartitionKey(form.ContractNumber)
            );

            _logger?.LogInformation($"Successfully saved BlindCheckForm with caseId '{form.ContractNumber}' to CosmosDB");
            return response.Resource;
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, $"Error saving BlindCheckForm with caseId '{form.ContractNumber}' to CosmosDB");
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