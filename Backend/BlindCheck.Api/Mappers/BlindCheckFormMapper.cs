using BlindCheck.Api.Data.Entities;
using BlindCheck.Api.Models;

namespace BlindCheck.Api.Mappers;

public static class BlindCheckFormMapper
{
    public static BlindCheckFormViewModel ToViewModel(BlindCheckForm entity)
    {
        return new BlindCheckFormViewModel
        {
            ContractNumber = entity.CaseInfo.ContractNumber,
            Diagram = entity.BlindCheckVerification.Diagram
                .Select(mp => new MemorialPlacementViewModel(mp.X, mp.Y, mp.Inscription))
                .ToList()
        };
    }
}