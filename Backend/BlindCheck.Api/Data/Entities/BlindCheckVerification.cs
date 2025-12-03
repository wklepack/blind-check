namespace BlindCheck.Api.Data.Entities;

public class BlindCheckVerification
{
    public string ConfirmedSpace { get; set; } = null!;
    public string ConfirmedCryptNiche { get; set; } = null!;
    public List<MemorialPlacement> Diagram { get; set; } = null!;
    public Verifications Verifications { get; set; } = null!;
    public AssociateSignature AssociateSignature { get; set; } = null!;
}
