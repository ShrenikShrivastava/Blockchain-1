// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertifyMe {
    
    struct Certificate {
        uint256 id;
        address student;
        string title;
        string workshopId;
        uint256 date;
        address issuer;
        bool isRevoked;
        string revocationReason;
        address revokedBy;
    }

    address public owner;
    
    mapping(address => bool) public authorizedIssuers;
    
    uint256 public certificateCount;
    mapping(uint256 => Certificate) public allCertificates;
    
    mapping(address => uint256[]) public studentCertificates;
    mapping(address => uint256[]) public issuerCertificates;
    
    mapping(address => mapping(string => bool)) public hasWorkshopCert;

    error NotAuthorized();
    error CertificateAlreadyIssued();
    error CertificateAlreadyRevoked();
    error InvalidRevoker();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAuthorized();
        _;
    }

    modifier onlyIssuer() {
        if (!authorizedIssuers[msg.sender]) revert NotAuthorized();
        _;
    }

    constructor() {
        owner = msg.sender; 
    }

    function addIssuer(address _issuer) public onlyOwner {
        authorizedIssuers[_issuer] = true;
    }

    function removeIssuer(address _issuer) public onlyOwner {
        authorizedIssuers[_issuer] = false;
    }

    function issueCertificate(
        address _student,
        string memory _title,
        string memory _workshopId
    ) public onlyIssuer {
        if (hasWorkshopCert[_student][_workshopId]) revert CertificateAlreadyIssued();

        uint256 newId = certificateCount;
        
        allCertificates[newId] = Certificate({
            id: newId,
            student: _student,
            title: _title,
            workshopId: _workshopId,
            date: block.timestamp,
            issuer: msg.sender,
            isRevoked: false,
            revocationReason: "",
            revokedBy: address(0)
        });

        studentCertificates[_student].push(newId);
        issuerCertificates[msg.sender].push(newId);
        hasWorkshopCert[_student][_workshopId] = true;

        certificateCount++;
    }

    function revokeCertificate(uint256 _id, string memory _reason) public {
        Certificate storage cert = allCertificates[_id];
        
        if (cert.isRevoked) revert CertificateAlreadyRevoked();
        if (msg.sender != cert.issuer && msg.sender != owner) revert InvalidRevoker();
        require(bytes(_reason).length > 0, "Revocation reason required");

        cert.isRevoked = true;
        cert.revocationReason = _reason;
        cert.revokedBy = msg.sender;
    }

    function isValidCertificate(address _student, string memory _workshopId) public view returns (bool) {
        uint256[] memory certIds = studentCertificates[_student];
        for (uint i = 0; i < certIds.length; i++) {
            Certificate memory cert = allCertificates[certIds[i]];
            if (keccak256(bytes(cert.workshopId)) == keccak256(bytes(_workshopId))) {
                return !cert.isRevoked;
            }
        }
        return false;
    }

    function getStudentCertificates(address _student) public view returns (Certificate[] memory) {
        uint256[] memory ids = studentCertificates[_student];
        Certificate[] memory certs = new Certificate[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            certs[i] = allCertificates[ids[i]];
        }
        return certs;
    }

    function getIssuerCertificates(address _issuer) public view returns (Certificate[] memory) {
        uint256[] memory ids = issuerCertificates[_issuer];
        Certificate[] memory certs = new Certificate[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            certs[i] = allCertificates[ids[i]];
        }
        return certs;
    }
}