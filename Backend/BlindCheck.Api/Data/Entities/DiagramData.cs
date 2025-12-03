namespace BlindCheck.Api.Data.Entities;

public class DiagramData
{
    public List<MemorialPlacement> MarkerPlacements { get; set; } = null!;
}

public class MemorialPlacement
{
    public int X { get; set; }
    public int Y { get; set; }
    public string Inscription { get; set; } = null!;
}
