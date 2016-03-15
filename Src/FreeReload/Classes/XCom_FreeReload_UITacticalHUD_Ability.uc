class XCom_FreeReload_UITacticalHUD_Ability extends UITacticalHUD_Ability;

simulated function UpdateData(int NewIndex, const out AvailableAction AvailableActionInfo)
{
	local XComGameState_BattleData BattleDataState;
	local bool bCoolingDown, isFreeReload;
	local int iTmp, i, MaxFreeReload;
	local UnitValue CurrentFreeReload;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local XComGameState_Item kPrimaryWeapon;
	local XComGameState_Ability AbilityState;   //Holds INSTANCE data for the ability referenced by AvailableActionInfo. Ie. cooldown for the ability on a specific unit
	local XComGameState_Unit UnitState;

	Index = NewIndex;

	//AvailableActionInfo function parameter holds UI-SPECIFIC data such as "is this ability visible to the HUD?" and "is this ability available"?
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);
	AbilityTemplate = AbilityState.GetMyTemplate();

	//Indicate whether the ability is available or not
	SetAvailable(AvailableActionInfo.AvailableCode == 'AA_Success');	

	//Cooldown handling
	bCoolingDown = AbilityState.IsCoolingDown();
	if(bCoolingDown)
		SetCooldown(m_strCooldownPrefix $ string(AbilityState.GetCooldownRemaining()));
	else
		SetCooldown("");

	if (AbilityTemplate != None)
	{
		//Set the icon
		Icon.LoadIcon(AbilityState.GetMyIconImage());
	
		// Set Antenna text, PC only
		if(Movie.IsMouseActive())
			SetAntennaText(Caps(AbilityState.GetMyFriendlyName()));
	}

	// Hacky solution for x-1 indicator and localization issue
	if (AbilityState.GetMyTemplateName() == 'Reload')
	{
		// I need this...
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
		UnitState.GetUnitValue('FreeReload', CurrentFreeReload);

		kPrimaryWeapon = AbilityState.GetSourceWeapon();
		UpgradeTemplates = kPrimaryWeapon.GetMyWeaponUpgradeTemplates();

		isFreeReload = false;
		MaxFreeReload = 0;
		for (i = 0; i < UpgradeTemplates.Length; ++i)
		{
			if (UpgradeTemplates[i].NumFreeReloads > 0)
			{
				if (CurrentFreeReload.fValue < UpgradeTemplates[i].NumFreeReloads)
				{
					isFreeReload = true;
					MaxFreeReload = UpgradeTemplates[i].NumFreeReloads;
					break;
				}
			}

		}
		if (isFreeReload) 
		{
			if(!bCoolingDown)
				SetCharge(m_strChargePrefix $ int(MaxFreeReload - CurrentFreeReload.fValue));
			else
				SetCharge("");
		} 
		else
		{
			iTmp = AbilityState.GetCharges();
			if(iTmp >= 0 && !bCoolingDown)
				SetCharge(m_strChargePrefix $ string(iTmp));
			else
				SetCharge("");
		}

	}
	else
	{
		iTmp = AbilityState.GetCharges();
		if(iTmp >= 0 && !bCoolingDown)
			SetCharge(m_strChargePrefix $ string(iTmp));
		else
			SetCharge("");
	}

	//Key the color of the ability icon on the source of the ability
	if (AbilityTemplate != None)
	{
		BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if(BattleDataState.IsAbilityObjectiveHighlighted(AbilityTemplate.DataName))
		{
			Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.OBJECTIVEICON_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		}
		else if(AbilityTemplate.AbilityIconColor != "")
		{
			Icon.EnableMouseAutomaticColor(AbilityTemplate.AbilityIconColor, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		}
		else
		{
			switch(AbilityTemplate.AbilitySourceName)
			{
			case 'eAbilitySource_Perk':
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.PERK_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;

			case 'eAbilitySource_Debuff':
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.BAD_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;

			case 'eAbilitySource_Psionic':
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;

			case 'eAbilitySource_Commander': 
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;
		
			case 'eAbilitySource_Item':
			case 'eAbilitySource_Standard':
			default:
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
			}
		}
	}

	// Simple hack to make it green!
	if (AbilityState.GetMyTemplateName() == 'Reload' && isFreeReload) 
	{
		Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
	}

	// HOTKEY LABEL (pc only)
	if(Movie.IsMouseActive())
	{
		iTmp = eTBC_Ability1 + Index;
		if( iTmp <= eTBC_Ability0 )
			SetHotkeyLabel(PC.Pres.m_kKeybindingData.GetPrimaryOrSecondaryKeyStringForAction(PC.PlayerInput, (eTBC_Ability1 + Index)));
		else
			SetHotkeyLabel("");
	}
	RefreshShine();
}