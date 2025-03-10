// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaimBounty {
    event ClaimBounty(uint256 idcard, address toAccount, uint256 amount);

    function claimable(uint256 idcard) external view returns (uint256 amount);

    function claimBounty(uint256 idcard, address toAccount)
        external
        returns (uint256 amount);
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IIDNFT {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface IMultiHonor {
    function POC(uint256 tokenId) external view returns (uint64);
}

abstract contract Administrable {
    address public admin;
    address public pendingAdmin;

    event SetAdmin(address admin);
    event TransferAdmin(address pendingAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function _setAdmin(address admin_) internal {
        admin = admin_;
        emit SetAdmin(admin);
    }

    function transferAdmin(address admin_) external onlyAdmin {
        pendingAdmin = admin_;
        emit TransferAdmin(pendingAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        _setAdmin(pendingAdmin);
        pendingAdmin = address(0);
    }
}

contract MonthlyBounty is IClaimBounty, Administrable {
    address public bountyToken;
    address public idnft;
    address public multiHonor;
    uint256 public immutable bountyDay;
    uint256 public pocFactor;

    mapping(uint256 => uint256) public historicPoints;

    event SetBountyToken(address bountyToken);
    event SetIDNFT(address idnft);
    event SetMultiHonor(address multiHonor);
    event Withdraw(uint256 amount, address to);

    constructor(
        address bountyToken_,
        address idnft_,
        address multiHonor_,
        uint256 pocFactor_
    ) {
        bountyDay = 25;

        _setAdmin(msg.sender);
        _setBountyToken(bountyToken_);
        _setIDNFT(idnft_);
        _setMultiHonor(multiHonor_);
        pocFactor = pocFactor_;
    }

    function _setBountyToken(address bountyToken_) internal {
        bountyToken = bountyToken_;
        emit SetBountyToken(bountyToken);
    }

    function _setIDNFT(address idnft_) internal {
        idnft = idnft_;
        emit SetIDNFT(idnft);
    }

    function _setMultiHonor(address multiHonor_) internal {
        multiHonor = multiHonor_;
        emit SetMultiHonor(multiHonor);
    }

    function setBountyToken(address bountyToken_) external onlyAdmin {
        _setBountyToken(bountyToken_);
    }

    function setPocFactor(uint256 _pocFactor) public onlyAdmin {
        require(
            _pocFactor <= 10000,
            "pocFactor must be less than or equal to 10000 "
        );
        pocFactor = _pocFactor;
    }

    function withdraw(uint256 amount, address to) external onlyAdmin {
        bool succ = IERC20(bountyToken).transfer(to, amount);
        require(succ);
        emit Withdraw(amount, to);
    }

    function claimable(uint256 idcard)
        public
        view
        override
        returns (uint256 amount)
    {
        uint256 dpoc = getDpoc(idcard);
        uint8 decimal = IERC20(bountyToken).decimals();
        amount = (pocFactor * dpoc * 10**decimal) / 10000;
        return amount;
    }

    function getDpoc(uint256 idcard) public view returns (uint256 dpoc) {
        uint256 poc = uint256(IMultiHonor(multiHonor).POC(idcard)) -
            initailReleasedPOC(idcard);
        dpoc = poc > historicPoints[idcard] ? poc - historicPoints[idcard] : 0;
        return dpoc;
    }

    function claimBounty(uint256 idcard, address toAccount)
        external
        override
        returns (uint256 amount)
    {
        require(
            IIDNFT(idnft).ownerOf(idcard) == msg.sender,
            "bounty distributor: not idcard owner"
        );
        uint256 dpoc = getDpoc(idcard);
        uint8 decimal = IERC20(bountyToken).decimals();
        amount = (pocFactor * dpoc * 10**decimal) / 10000;
        bool success = IERC20(bountyToken).transfer(toAccount, amount);
        require(success, "bounty distributor: send bounty token failed");
        historicPoints[idcard] += dpoc;
        emit ClaimBounty(idcard, toAccount, amount);
        return amount;
    }

    function initailReleasedPOC(uint256 tokenId) public pure returns (uint256) {
        if (tokenId == 0) {
            return 2610;
        }
        if (tokenId == 1) {
            return 38080;
        }
        if (tokenId == 2) {
            return 2001;
        }
        if (tokenId == 4) {
            return 2500;
        }
        if (tokenId == 7) {
            return 2889;
        }
        if (tokenId == 8) {
            return 93;
        }
        if (tokenId == 10) {
            return 49;
        }
        if (tokenId == 13) {
            return 2000;
        }
        if (tokenId == 25) {
            return 1541;
        }
        if (tokenId == 29) {
            return 1821;
        }
        if (tokenId == 30) {
            return 1073;
        }
        if (tokenId == 32) {
            return 132;
        }
        if (tokenId == 64) {
            return 4225;
        }
        if (tokenId == 1126) {
            return 2000;
        }
        if (tokenId == 15314) {
            return 2000;
        }
        if (tokenId == 15315) {
            return 2000;
        }
        if (tokenId == 15316) {
            return 2000;
        }
        if (tokenId == 15318) {
            return 2500;
        }
        if (tokenId == 15319) {
            return 2000;
        }
        if (tokenId == 15370) {
            return 900;
        }
        return 0;
    }
}
