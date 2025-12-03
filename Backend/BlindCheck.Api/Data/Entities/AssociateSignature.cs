namespace BlindCheck.Api.Data.Entities;

public class AssociateSignature
{
    public string Name { get; set; } = null!;
    public string SignatureBase64 { get; set; } = null!;
    public string Date { get; set; } = null!;
}
