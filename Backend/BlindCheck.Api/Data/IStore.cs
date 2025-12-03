using BlindCheck.Api.Data.Entities;

namespace BlindCheck.Api.Data;

public interface IStore
{
    public Task<BlindCheckForm?> GetBlindCheckFormByCaseIdAsync(string contractNumber);
}