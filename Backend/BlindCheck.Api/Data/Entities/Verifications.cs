namespace BlindCheck.Api.Data.Entities;

public class Verifications
{
    public VerificationItem AgreesWithAdjacentInterments { get; set; } = null!;
    public VerificationItem AgreesWithNumberedPins { get; set; } = null!;
    public VerificationItem AgreesWithPermanentRecords { get; set; } = null!;
    public VerificationItem AgreesWithIntermentOrder { get; set; } = null!;
    public VerificationItem AgreesWithDisintermentOrder { get; set; } = null!;
}
