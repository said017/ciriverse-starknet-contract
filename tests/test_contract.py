"""contract.cairo test file."""
import os

import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "ciri_profile.cairo")
# CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

# def compile(path):
#     return compile_starknet_files(
#         files=[os.path.join(CONTRACT_SRC, path)],
#         debug_info=True
#     )

# @pytest.fixture(scope="session")
# def compiled_ciri():
#     return compile("ciri_profile.cairo")

# @pytest_asyncio.fixture
# async def starknet():
#     # Create a new Starknet class that simulates the StarkNet
#     return await Starknet.empty()

# @pytest_asyncio.fixture
# async def ciri_contract(starknet: Starknet, compiled_ciri):
#     ciri_contract = await starknet.deploy(compiled_ciri)
#     return ciri_contract

# def invoke_ciri(call):
#     return call.invoke()


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
# @pytest.mark.asyncio
# async def test_create_profile():
#     """Test increase_balance method."""
#     # Create a new Starknet class that simulates the StarkNet
#     # system.
#     starknet = await Starknet.empty()

#     # Deploy the contract.
#     contract = await starknet.deploy(
#         source=CONTRACT_FILE,
#         constructor_calldata=[1398892900, 1398892900, 1443860154347853406231104625532276639515718725489596953668649964320565133418, 2774287484619332564597403632816768868845110259953541691709975889937073775752, 1, 184555836509371486644298270517380613565396767415278678887948391494588524912]

#     )

#     # Invoke create_profile().
#     await contract.create_profile(1398892900, [1398892900]).execute()
#     # await invoke_ciri(ciri_contract.create_profile(nickname=1398892900, pic_len=1, pic=1398892900))

#     # Check the result of get_profile_counter().
#     execution_info = await contract.get_profile_counter().call()
#     assert execution_info.result == (1,)
