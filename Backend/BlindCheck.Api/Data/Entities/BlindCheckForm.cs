namespace BlindCheck.Api.Data.Entities;

public class BlindCheckForm
{
    public required string ContractNumber { get; init; }
    public Counselor Counselor  { get; set; } = null!;
    public required List<MemorialPlacement> MarkerPlacements { get; init; }
    public required BlindCheckVerification BlindCheckVerification { get; init; }
}