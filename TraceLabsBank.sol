// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TraceLabsBank is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BANK_OWNER_ROLE = keccak256("BANK_OWNER_ROLE");
    IERC20  public bankToken; // token for staking and reward
    uint256 public poolInterval; // time T0
    uint256 public deploymentTime; // time t
    uint256 public R1; // percentage return of R1 pool. in wei amounts.
    uint256 public R2; // percentage return of R1 pool. in wei amounts.
    uint256 public R3; // percentage return of R1 pool. in wei amounts.

    mapping(address => uint256) public accountLedger; // wallet -> amount
    mapping(uint256 => uint256) public poolBalance; 
    uint256 public totalStaked ; 
    uint256 public totalUsers;

    constructor(address _tokenAddress, uint256 _poolInterval) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(BANK_OWNER_ROLE, msg.sender);

        R1 = 200000000000000000 ; // 20% in wei is 20 ether / 100.
        R2 = 300000000000000000 ; // 30% in wei is 20 ether / 100.
        R3 = 500000000000000000 ; // 50% in wei is 20 ether / 100.      

        deploymentTime = block.timestamp;
        bankToken = IERC20(_tokenAddress);
        poolInterval = _poolInterval;
    }

/**
    @dev to deposit amount for staking
    @param _amount , amount to deposit for staking
 */
    function deposit(uint256 _amount) public whenNotPaused {
        require( block.timestamp < poolInterval + deploymentTime, "Deposit Period has ended" );
        // Approval and token amount checking already implemented in ERC20 standard.
        bankToken.transferFrom( msg.sender, address(this), _amount );
        


        if ( accountLedger[msg.sender] == 0 )
            totalUsers += 1;
        
        accountLedger[msg.sender] += _amount  ;

        totalStaked += _amount ;



    }

/**
    @dev to withdraw rewards 
 */
    function withdrawRewards() public whenNotPaused {
        require( block.timestamp > (poolInterval  * 2 ) + deploymentTime, "Lock Period is active" );

        uint256 _amount = calculateReward();
        _amount  += accountLedger[msg.sender] ;

        totalStaked -= accountLedger[msg.sender];

        accountLedger[msg.sender] = 0; 

        totalUsers -= 1;

        if ( _amount > 0 ) {
        // bankToken.approve(msg.sender, _amount);
        bankToken.transfer( msg.sender ,  _amount );
        }
        else
            revert("Nothing to withdraw");
    }


    /**
    @dev read only function to see estimated rewards 
    */

    function calculateReward() public view returns(uint256) {
        
        if( totalStaked == 0)
        return 0;

        uint256 reward;
        
        // R1 R2 R3 rewards
        if ( block.timestamp > (poolInterval  * 4 ) + deploymentTime ) {
            reward  += ( accountLedger[msg.sender]  / totalStaked ) * poolBalance[1];
            reward  += ( accountLedger[msg.sender]  / totalStaked ) * poolBalance[2];
            reward  += ( accountLedger[msg.sender]  / totalStaked ) * poolBalance[3];
        }
        // R1 and R2 rewards
        else if ( block.timestamp > (poolInterval  * 3 ) + deploymentTime ) {
            reward  += ( accountLedger[msg.sender]  / totalStaked ) * poolBalance[1];
            reward  += ( accountLedger[msg.sender]  / totalStaked ) * poolBalance[2];
        }
        // R1 rewards only
        else if ( block.timestamp > (poolInterval  * 2 ) + deploymentTime ) {
            reward  += ( accountLedger[msg.sender]  / totalStaked ) * poolBalance[1];
        }

        return reward;
    }

    /**
        ADMINISTRATIVE FUNCTIONS
    */


    /**
    @dev to withraw any remaining rewards or balances after t + T4 time
    -- ONLY used by BANK_OWNER -- 
    */
    function withdrawRemaining() public onlyRole(BANK_OWNER_ROLE) {
        require( block.timestamp > (poolInterval  * 4 ) + deploymentTime, "t + T4 has not passed yet");
        require( totalUsers == 0, "users with staked amount still available");
    
        bankToken.transferFrom(address(this), msg.sender ,  bankToken.balanceOf(address(this)) );

    }


    /**
    @dev to setup pool returns and to transfer tokens to pool
    -- ONLY used by BANK_OWNER -- 
    @param _R1 , wei amount to return of R1. For Example 20% is 20 ether / 100 so 200000000000000000
    @param _R2 , wei amount to return of R1. For Example 30% is 30 ether / 100 so 300000000000000000
    @param _R3 , wei amount to return of R1. For Example 50% is 50 ether / 100 so 500000000000000000
    @param _amount ,  amouun to deposit in reward pool
    */
    function setPoolBalance(uint256 _R1, uint256 _R2, uint256 _R3, uint256 _amount ) public onlyRole(BANK_OWNER_ROLE) {

            bankToken.transferFrom( msg.sender, address(this), _amount );

            R1 = _R1 ; 
            R2 = _R2 ; 
            R3 = _R3 ; 

            poolBalance[1] = _amount * R1 / 1 ether;
            poolBalance[2] = _amount * R2 / 1 ether;
            poolBalance[3] = _amount * R3 / 1 ether;
    }

    /**
    @dev to setup pool interval time T
    -- ONLY used by BANK_OWNER -- 
    @param _poolInterval , pool interval T
    */

    function setpoolInterval(uint256 _poolInterval) public onlyRole(BANK_OWNER_ROLE){
        poolInterval = _poolInterval;
    }


    /**
    @dev to setup token which will staked and use for rewards
    -- ONLY used by BANK_OWNER -- 
    @param _token , token address 
    */

    function setBankToken(address _token) public onlyRole(BANK_OWNER_ROLE){
        bankToken = IERC20(_token);
    }



    /**
    @dev to pause the contract
    */

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
    @dev to unpause the contract
    */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


}