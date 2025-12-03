using System.Text.Json.Serialization;

namespace BlindCheck.Api.Data.Entities;

public class BlindCheckForm
{
    [JsonPropertyName("id")]
    public string Id => ContractNumber;

    public required string ContractNumber { get; init; }
    public Counselor Counselor  { get; set; } = null!;
    public Decedent Decedent  { get; set; } = null!;
    public required List<MemorialPlacement> MarkerPlacements { get; init; }
    public required BlindCheckVerification BlindCheckVerification { get; init; }
}