namespace BlindCheck.Api.Data.Entities;

public class BlindCheckVerification
{
    public bool IsVerified { get; set; }
    public bool VerifiedBy { get; set; }
    public DateTime VerifiedAt { get; set; }
}
