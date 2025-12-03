namespace BlindCheck.Api.Models;

public class BlindCheckFormViewModel
{
    public required string ContractNumber { get; init; }
    public required List<MemorialPlacementViewModel> Diagram { get; init; }
}

public record MemorialPlacementViewModel(int X, int Y, string Inscription);