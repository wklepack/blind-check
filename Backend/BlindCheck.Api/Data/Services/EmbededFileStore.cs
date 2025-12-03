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
        }

        await using var stream = _assembly.GetManifestResourceStream(matchingResource);
        if (stream == null)
        {
            throw new InvalidOperationException($"Could not load embedded resource stream for '{matchingResource}'");
        }

        var form = await JsonSerializer.DeserializeAsync<BlindCheckForm>(stream, _jsonOptions);

        return form ?? throw new InvalidOperationException($"Failed to deserialize BlindCheckForm from '{matchingResource}'");
    }
}