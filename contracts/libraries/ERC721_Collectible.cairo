// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165

from libraries.ShortString import uint256_to_ss
from libraries.Array import concat_arr

//
// Storage
//

@storage_var
func ERC721_token_uri_c(token_id : Uint256, index : felt) -> (res : felt){
}

@storage_var
func ERC721_token_uri_len_c(token_id : Uint256) -> (res : felt){
}


func ERC721_Metadata_tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> ( token_uri_len : felt, token_uri : felt*){
    alloc_locals;

    let exists : felt = ERC721._exists(token_id);
    assert exists = 1;

    let (local _token_uri) = alloc();
    let (local _token_uri_len) = ERC721_token_uri_len_c.read(token_id);

    _ERC721_Metadata_TokenURI(token_id, _token_uri_len, _token_uri);

    // let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id);
    // let (token_uri, token_uri_len) = concat_arr(
    //     base_token_uri_len, base_token_uri
    // );

    return (token_uri_len=_token_uri_len, token_uri=_token_uri);
}

func _ERC721_Metadata_TokenURI{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}( token_id : Uint256, token_uri_len : felt, token_uri : felt*){
    if (token_uri_len == 0) {
        return ();
    }
    let (base) = ERC721_token_uri_c.read(token_id, token_uri_len);
    assert [token_uri] = base;
    _ERC721_Metadata_TokenURI( token_id=token_id,
       token_uri_len=token_uri_len - 1, token_uri=token_uri + 1
    );
    return ();
}

func ERC721_Metadata_setTokenURI{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256, token_uri_len : felt, token_uri : felt*){
    _ERC721_Metadata_setTokenURI(token_id, token_uri_len, token_uri);
    ERC721_token_uri_len_c.write(token_id, token_uri_len);
    return ();
}

func _ERC721_Metadata_setTokenURI{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256, token_uri_len : felt, token_uri : felt*){
    if (token_uri_len == 0) {
        return ();
    }
    ERC721_token_uri_c.write(token_id=token_id, index=token_uri_len, value=[token_uri]);
    _ERC721_Metadata_setTokenURI(token_id=token_id, token_uri_len=token_uri_len - 1, token_uri=token_uri + 1);
    return ();
}
