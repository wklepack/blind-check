using System.Reflection;
using System.Text.Json;
using BlindCheck.Api.Data.Entities;

namespace BlindCheck.Api.Data.Services;

public class EmbededFileStore(ILogger<EmbededFileStore> logger) : IStore
{
    private readonly Assembly _assembly = Assembly.GetExecutingAssembly();
    private readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public async Task<BlindCheckForm?> GetBlindCheckFormByCaseIdAsync(string contractNumber)
    {
        var resourceName = $"{contractNumber}.json";

        // Get all embedded resource names to find the matching one
        var allResources = _assembly.GetManifestResourceNames();
        var matchingResource = allResources.FirstOrDefault(r => r.EndsWith(resourceName, StringComparison.OrdinalIgnoreCase));

        if (matchingResource == null)
        {
            logger.LogInformation($"Could not find embedded resource for '{resourceName}'");
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
                    logger.LogWarning($"Could not load embedded resource stream for '{resourceName}'");
                    continue;
                }

                var form = await JsonSerializer.DeserializeAsync<BlindCheckForm>(stream, _jsonOptions);
                if (form != null)
                {
                    forms.Add(form);
                }
                else
                {
                    logger.LogWarning($"Failed to deserialize BlindCheckForm from '{resourceName}'");
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, $"Error loading embedded resource '{resourceName}'");
            }
        }

        return forms;
    }
}