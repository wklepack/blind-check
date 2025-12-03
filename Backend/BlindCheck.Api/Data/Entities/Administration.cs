namespace BlindCheck.Api.Data.Entities;

public class Administration
{
    public string AdminName { get; set; } = null!;
    public DateTime DateTimeReceived { get; set; }
    public string AssignedTo { get; set; } = null!;
}
