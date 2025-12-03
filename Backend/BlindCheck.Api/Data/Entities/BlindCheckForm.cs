namespace BlindCheck.Api.Data.Entities;

public class BlindCheckForm
{
    public FormMetadata FormMetadata { get; set; } = null!;
    public CaseInfo CaseInfo { get; set; } = null!;
    public ArrangementCounselor ArrangementCounselor { get; set; } = null!;
    public LocationDetails LocationDetails { get; set; } = null!;
    public Administration Administration { get; set; } = null!;
    public BlindCheckVerification BlindCheckVerification { get; set; } = null!;
    public MemorialBlindCheck MemorialBlindCheck { get; set; } = null!;
}
