struct FReloadMontages {
    UPROPERTY()
    UAnimMontage GunHip;

    UPROPERTY()
    UAnimMontage GunADS;

    UPROPERTY()
    UAnimMontage CharacterHip;

    UPROPERTY()
    UAnimMontage CharacterADS;
}

class AWeaponBase : AActor {
    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent Mesh;

    UPROPERTY()
    UAnimMontage FireMontage;

    UPROPERTY()
    FReloadMontages ReloadMontages;

    UPROPERTY()
    float ImpactVolume;

    bool bClipAttached;
    default bClipAttached = true;

    void Fire() {
        Mesh.GetAnimInstance().Montage_Play(FireMontage);
    }

    void Reload(bool bIsADS) {
        UAnimMontage Montage = bIsADS ? ReloadMontages.GunADS : ReloadMontages.GunHip;
        Mesh.GetAnimInstance().Montage_Play(Montage);
    }

    UAnimMontage GetCharacterReloadMontage(bool bIsADS) const {
        return bIsADS ? ReloadMontages.CharacterADS : ReloadMontages.CharacterHip;
    }

    UFUNCTION()
    void SetClipAttached(bool bAttached) {
        bClipAttached = bAttached;
    }

    UFUNCTION()
    bool GetClipAttached() const {
        return bClipAttached;
    }
}