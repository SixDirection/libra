// The genesis module. This defines the majority of the Move functions that
// are executed, and the order in which they are executed in genesis. Note
// however, that there are certain calls that remain in Rust code in
// genesis (for now).
address 0x1 {
module Genesis {
    use 0x1::AccountLimits;
    use 0x1::Coin1;
    use 0x1::Coin2;
    use 0x1::DualAttestationLimit;
    use 0x1::Event;
    use 0x1::LBR;
    use 0x1::Libra;
    use 0x1::LibraAccount;
    use 0x1::LibraBlock;
    use 0x1::LibraConfig;
    use 0x1::LibraSystem;
    use 0x1::LibraTimestamp;
    use 0x1::LibraTransactionTimeout;
    use 0x1::LibraVersion;
    use 0x1::LibraWriteSetManager;
    use 0x1::Signer;
    use 0x1::TransactionFee;
    use 0x1::Roles;
    use 0x1::LibraVMConfig;


    fun initialize(
        lr_account: &signer,
        tc_account: &signer,
        tc_addr: address,
        genesis_auth_key: vector<u8>,
        publishing_option: vector<u8>,
        instruction_schedule: vector<u8>,
        native_schedule: vector<u8>,
    ) {
        let dummy_auth_key_prefix = x"00000000000000000000000000000000";

        Roles::grant_root_association_role(lr_account);
        LibraAccount::grant_association_privileges(lr_account);
        Roles::grant_treasury_compliance_role(tc_account, lr_account);

        Event::publish_generator(lr_account);

        // Event and On-chain config setup
        LibraConfig::initialize(
            lr_account,
        );

        // Currency setup
        Libra::initialize(
            lr_account,
        );

        // Currency setup
        let (coin1_mint_cap, coin1_burn_cap) = Coin1::initialize(
            lr_account,
            tc_account,
        );
        let (coin2_mint_cap, coin2_burn_cap) = Coin2::initialize(
            lr_account,
            tc_account,
        );
        LBR::initialize(
            lr_account,
            tc_account,
        );

        LibraAccount::initialize(lr_account);
        LibraAccount::create_root_association_account(
            Signer::address_of(lr_account),
            copy dummy_auth_key_prefix,
        );

        // Register transaction fee resource
        TransactionFee::initialize(
            lr_account,
            tc_account,
        );

        // Create the treasury compliance account
        LibraAccount::create_treasury_compliance_account(
            lr_account,
            tc_account,
            tc_addr,
            copy dummy_auth_key_prefix,
            coin1_mint_cap,
            coin1_burn_cap,
            coin2_mint_cap,
            coin2_burn_cap,
        );
        AccountLimits::publish_unrestricted_limits(tc_account);
        AccountLimits::certify_limits_definition(tc_account, tc_addr);

        LibraTransactionTimeout::initialize(lr_account);
        LibraSystem::initialize_validator_set(
            lr_account,
        );
        LibraVersion::initialize(
            lr_account,
        );

        DualAttestationLimit::initialize(
            lr_account,
            tc_account,
        );
        LibraBlock::initialize_block_metadata(lr_account);
        LibraWriteSetManager::initialize(lr_account);
        LibraTimestamp::initialize(lr_account);

        let assoc_rotate_key_cap = LibraAccount::extract_key_rotation_capability(lr_account);
        LibraAccount::rotate_authentication_key(&assoc_rotate_key_cap, copy genesis_auth_key);
        LibraAccount::restore_key_rotation_capability(assoc_rotate_key_cap);

        LibraVMConfig::initialize(
            lr_account,
            lr_account,
            publishing_option,
            instruction_schedule,
            native_schedule,
        );

        let config_rotate_key_cap = LibraAccount::extract_key_rotation_capability(lr_account);
        LibraAccount::rotate_authentication_key(&config_rotate_key_cap, copy genesis_auth_key);
        LibraAccount::restore_key_rotation_capability(config_rotate_key_cap);

        let tc_rotate_key_cap = LibraAccount::extract_key_rotation_capability(tc_account);
        LibraAccount::rotate_authentication_key(&tc_rotate_key_cap, copy genesis_auth_key);
        LibraAccount::restore_key_rotation_capability(tc_rotate_key_cap);

        // Restore privileges

        // Mark that genesis has finished. This must appear as the last call.
        LibraTimestamp::set_time_has_started(lr_account);
    }

}
}
