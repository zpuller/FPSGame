class UPlayerStats : UActorComponent {
    UPROPERTY()
    TSubclassOf<UPlayerStatsWidget> PlayerStatsWidgetClass;

    UPlayerStatsWidget Widget;

    ACharacter CharacterOwner;

    int Health;
    int MaxHealth;
    default MaxHealth = 100;

    void UpdateHealthBar() {
        if (!IsValid(Widget)) {
            return;
        }

        Widget.SetPercent(Health / 100.0);
    }

    void AddHealth(int AddlHealth) {
        Health = Math::Min(Health + AddlHealth, MaxHealth);
        UpdateHealthBar();
    }

    UFUNCTION()
    bool ReduceHealth(int Damage) {
        Health = Math::Max(Health - Damage, 0);
        UpdateHealthBar();

        return Health == 0;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CharacterOwner = Cast<ACharacter>(GetOwner());
        Widget = Cast<UPlayerStatsWidget>(WidgetBlueprint::CreateWidget(PlayerStatsWidgetClass,
                CharacterOwner.GetLocalViewingPlayerController()));
        
        Widget.AddToViewport();

        Health = MaxHealth;
        UpdateHealthBar();
    }
}