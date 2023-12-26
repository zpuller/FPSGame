enum EFireMode {
    Auto = 0,
    SemiAuto = 1,
}

struct FWeaponStats {
    UPROPERTY()
    EFireMode FireMode;

    UPROPERTY()
    int MaxAmmo;

    UPROPERTY()
    float Damage;

    UPROPERTY()
    float FireRate;
}

struct FWeaponData {
    UPROPERTY()
    FName Name;

    UPROPERTY()
    UTexture2D Icon;

    UPROPERTY()
    TSoftClassPtr<AWeaponBase> WeaponClassRef;

    UPROPERTY()
    FWeaponStats WeaponStats;
}

class UInventoryComponent : UActorComponent {
    UPROPERTY()
    TSubclassOf<UAmmoWidgetScript> AmmoWidgetClass;

    UPROPERTY()
    UDataTable WeaponDataTable;

    UPROPERTY()
    TArray<int> Inventory;

    int CurItemIndex;
    FWeaponData CurItem;
    TMap<TSoftClassPtr<AWeaponBase>, int> Ammo;
    ACharacter CharacterOwner;
    UAmmoWidgetScript AmmoWidget;

    FOnSoftClassLoaded NoopCallback;

    UFUNCTION()
    void NoopOnLoaded(UClass LoadedClass) {}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CharacterOwner = Cast<ACharacter>(GetOwner());
        AmmoWidget = Cast<UAmmoWidgetScript>(WidgetBlueprint::CreateWidget(AmmoWidgetClass,
                CharacterOwner.GetLocalViewingPlayerController()));
        
        AmmoWidget.AddToViewport();

        NoopCallback = FOnSoftClassLoaded(this, n"NoopOnLoaded");

        for (int I : Inventory) {
            FWeaponData WeaponData;
            if (WeaponDataTable.FindRow(FName(f"{I}"), WeaponData)) {
                Ammo.Add(WeaponData.WeaponClassRef, WeaponData.WeaponStats.MaxAmmo);
                WeaponData.WeaponClassRef.LoadAsync(NoopCallback);
            }
        }
    }

    TSubclassOf<AWeaponBase> EquippedItem(FOnSoftClassLoaded OnWeaponLoaded) {
        WeaponDataTable.FindRow(FName(f"{Inventory[CurItemIndex]}"), CurItem);
        AmmoWidget.SetAmmo(GetAmmo());

        CurItem.WeaponClassRef.LoadAsync(OnWeaponLoaded);
        return CurItem.WeaponClassRef.Get();
    }

    void DecrementAmmo() {
        int NewAmmo = GetAmmo();
        NewAmmo--;
        Ammo.Add(CurItem.WeaponClassRef, NewAmmo);
        AmmoWidget.SetAmmo(NewAmmo);
    }

    int GetAmmo() const {
        int CurAmmo;
        Ammo.Find(CurItem.WeaponClassRef, CurAmmo);

        return CurAmmo;
    }

    EFireMode GetFireMode() const {
        return CurItem.WeaponStats.FireMode;
    }

    float GetFireRate() const {
        return CurItem.WeaponStats.FireRate;
    }

    void SwitchWeapon() {
        CurItemIndex = (CurItemIndex + 1) % Inventory.Num();
    }

    int GetMaxAmmo() const {
        return CurItem.WeaponStats.MaxAmmo;
    }

    bool CanReload() const {
        return GetAmmo() < GetMaxAmmo();
    }

    float GetDamage() const {
        return CurItem.WeaponStats.Damage;
    }

    UFUNCTION()
    void Reload() {
        int NewAmmo = GetMaxAmmo();
        Ammo.Add(CurItem.WeaponClassRef, NewAmmo);
        AmmoWidget.SetAmmo(NewAmmo);
    }
}