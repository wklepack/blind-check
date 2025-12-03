namespace BlindCheck.Api.Data.Entities;

public class ArrangementCounselor
{
    public string CounselorName { get; set; } = null!;
    public string ConferenceDate { get; set; } = null!;
    public DecedentName DecedentName { get; set; } = null!;
    public IntermentService IntermentService { get; set; } = null!;
    public LocationDetails LocationDetails { get; set; } = null!;
}
