import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import MetadataViews from "../contracts/MetadataViews.cdc"
import ExampleNFT from "../contracts/ExampleNFT.cdc"
import NFTForwarding from "../contracts/utility/NFTForwarding.cdc"

/// This transaction is what an account would run
/// to set itself up to forward NFTs to a designated
/// recipient's collection

transaction(recipientAddress: Address) {

    prepare(signer: AuthAccount) {
        // Return early if the account already has an NFTForwarder
        if signer.borrow<&NFTForwarding.NFTForwarder>(from: NFTForwarding.NFTForwarderStoragePath) != nil {
            return
        }

        // Get Receiver Capability from the recipientAddress account
        let receiverCapability = getAccount(recipientAddress)
            .getCapability<&{NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPublicPath)

        // Make sure the CollectionPublic capability is valid before minting the NFT
        if !receiverCapability.check() { panic("CollectionPublic capability is not valid!") }

        // Create a new NFTForwarder resource
        let forwarder <- NFTForwarding.createNewNFTForwarder(recipient: receiverCapability)

        // save it to the account
        signer.save(<-forwarder, to: NFTForwarding.NFTForwarderStoragePath)

        // unlink existing Collection capabilities from PublicPath
        if signer.getCapability(ExampleNFT.CollectionPublicPath)
            .check<&{
                NonFungibleToken.CollectionPublic,
                ExampleNFT.ExampleNFTCollectionPublic,
                MetadataViews.ResolverCollection
            }>() {
            signer.unlink(ExampleNFT.CollectionPublicPath)
        }

        // create a public capability for the forwarder where the collection would be
        signer.link<&{NonFungibleToken.Receiver}>(
            ExampleNFT.CollectionPublicPath,
            target: NFTForwarding.NFTForwarderStoragePath
        )
    }
}
