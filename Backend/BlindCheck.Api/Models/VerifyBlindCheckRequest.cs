namespace BlindCheck.Api.Models;

public class VerifyBlindCheckRequest
{
    public required bool IsVerified { get; set; }
    public required string UserName { get; set; }
}
