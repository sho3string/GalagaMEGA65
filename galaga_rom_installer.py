#!/usr/bin/env python3
import os
import sys
import zipfile
import tempfile
import shutil
import hashlib

# Galaga Midway Set 1

MIDWAY_SET1_FILES = [
    "3200a.bin", "3300b.bin", "3400c.bin", "3500d.bin", 
    "3600e.bin",
    "3700g.bin", 
    "2600j.bin", 
    "2800l.bin","2700k.bin", 
    "prom-1.1d", "prom-2.5c", "prom-3.1c", "prom-4.2n", "prom-5.5n",
    "51xx.bin", "54xx.bin"

]

MIDWAY_SET1_CHK = {
    "2600j.bin": "5e68d9567938d80ebba91168f511b1952dba19658a841b73811c947fd6649f98", 
    "2700k.bin": "e8a614ace39650e743d2a4c4641c751eb958276215e2d68983c90a6cbc50fe47",
    "2800l.bin": "550119a20c3d9240bccefb6a0af2c3d00d3748dad7596bc8bab3c641126a53b7",
    "3200a.bin": "701e8d65e1edc6d12f56e4f306463ad95384d1f959add83cbefca45d2e7646df",
    "3300b.bin": "43ea28a9664c25449d8e3776bf902bd8a3e61754b330a88284c497934ab7b673",
    "3400c.bin": "8d2727defa3a7d7953d79992ba77fb53010acc13a37fe410b7652cbf77167392",
    "3500d.bin": "b98e7bc91af65391b481055f1c5a80ffe79c1093aadd78883baf443ecf2d6b2b",
    "3600e.bin": "fba08538baa7ffc74d1441f1d0c666619a2020899d11eaee360551fea58eb3e8",
    "3700g.bin": "28ea2804941a6d5d5c5f95ded739f3c65293471bfb2b7cbebe0b68a45936fda1",
    "51xx.bin": "bd1c1fddde888550611fdb4ae29bc06d8ac2d2c6a2771ebbff243ec109caf26e",
    "54xx.bin": "85c8570b91342ab729bd775c500a3e7245d655a0bab2fed6356e37ea388848e8",
    "prom-1.1d": "079f5fd72fc52bfa9354927ecea9aaba240b1527f1a5951ee15975286b166b3b",
    "prom-2.5c": "8c34002652e587aa19a77bff9040d870af18b4b2fe5c5f0ed962899386e0e751",
    "prom-3.1c": "a3e80d099f7bcbfdd9a64239bda2e5e916c696d5dfb9294053bae57c46e184b1",
    "prom-4.2n": "6534ac170c6a8b0f567179bb4f24d4ab8337e3561e5f229a7bd9b128d29fed4f",
    "prom-5.5n": "5c2d0637794badb9a214324da3fd9ebbcd282a5c0f3a778fe6219fdba1c3b91a"
}

# Galaga Midway Set 1 - fast Shoot

MIDWAYFS_SET1_FILES = [
    "3200a.bin", "3300b.bin", "3400c.bin", "3500d.bin", 
    "3600fast.bin",    # fast shoot.
    "3700g.bin", 
    "2600j.bin", 
    "2800l.bin","2700k.bin", 
    "prom-1.1d", "prom-2.5c", "prom-3.1c", "prom-4.2n", "prom-5.5n",
    "51xx.bin", "54xx.bin"
    
]

MIDWAYFS_SET1_CHK = {
    "2600j.bin": "5e68d9567938d80ebba91168f511b1952dba19658a841b73811c947fd6649f98", 
    "2700k.bin": "e8a614ace39650e743d2a4c4641c751eb958276215e2d68983c90a6cbc50fe47",
    "2800l.bin": "550119a20c3d9240bccefb6a0af2c3d00d3748dad7596bc8bab3c641126a53b7",
    "3200a.bin": "701e8d65e1edc6d12f56e4f306463ad95384d1f959add83cbefca45d2e7646df",
    "3300b.bin": "43ea28a9664c25449d8e3776bf902bd8a3e61754b330a88284c497934ab7b673",
    "3400c.bin": "8d2727defa3a7d7953d79992ba77fb53010acc13a37fe410b7652cbf77167392",
    "3500d.bin": "b98e7bc91af65391b481055f1c5a80ffe79c1093aadd78883baf443ecf2d6b2b",
    "3600fast.bin": "31ef37f0219dbdfe30b7010f4671e5c652df6b62116c06d9914c226619bdcce0", # fast shoot
    "3700g.bin": "28ea2804941a6d5d5c5f95ded739f3c65293471bfb2b7cbebe0b68a45936fda1",
    "51xx.bin": "bd1c1fddde888550611fdb4ae29bc06d8ac2d2c6a2771ebbff243ec109caf26e",
    "54xx.bin": "85c8570b91342ab729bd775c500a3e7245d655a0bab2fed6356e37ea388848e8",
    "prom-1.1d": "079f5fd72fc52bfa9354927ecea9aaba240b1527f1a5951ee15975286b166b3b",
    "prom-2.5c": "8c34002652e587aa19a77bff9040d870af18b4b2fe5c5f0ed962899386e0e751",
    "prom-3.1c": "a3e80d099f7bcbfdd9a64239bda2e5e916c696d5dfb9294053bae57c46e184b1",
    "prom-4.2n": "6534ac170c6a8b0f567179bb4f24d4ab8337e3561e5f229a7bd9b128d29fed4f",
    "prom-5.5n": "5c2d0637794badb9a214324da3fd9ebbcd282a5c0f3a778fe6219fdba1c3b91a"
}


# Galaga Midway Set 2

MIDWAY_SET2_FILES = [
    "mk2-1","mk2-2","3400c.bin","mk2-4",                                            # rom1 - CPU1
    "gg1-5.3f",                                                                     # rom2 - SUBCPU
    "gg1-7b.2c",                                                                    # rom3 - SNDCPU
    "gg1-9.4l",                                                                     # GFX1
    "gg1-11.4d","gg1-10.4f",                                                        # GFX2
    "prom-1.1d", "prom-2.5c", "prom-3.1c", "prom-4.2n", "prom-5.5n",                # spr lookup, char lookup, palette proms
    "51xx.bin", "54xx.bin"                                                          # mcus
]


MIDWAY_SET2_CHK = {
    
    "mk2-1": "7824027a0e25a4ef8af6d67f5166ad40e045b5cfe8e1ab6048daa51d20c59051",
    "mk2-2": "0a91a46e78839454f7676347963cc5ab6c2a6c40b610ce541f9c22306e4bd0f8",
    "3400c.bin": "8d2727defa3a7d7953d79992ba77fb53010acc13a37fe410b7652cbf77167392",
    "mk2-4": "e829cd0bfdd653f4bada2f7921372c0f8127ee61d57d66b60793da07f8f13e69",
    "gg1-5.3f": "8f1c227ab936b82fb62dc010bec01779c09e192afab48f53542b629f51da1c8d",
    "gg1-7b.2c": "f6b24ea6d3ece28350763f5f5550a1024d0ca23b9b85e5772994ab0558c8cdc1",
    "gg1-9.4l": "5e68d9567938d80ebba91168f511b1952dba19658a841b73811c947fd6649f98",
    "gg1-11.4d": "550119a20c3d9240bccefb6a0af2c3d00d3748dad7596bc8bab3c641126a53b7",
    "gg1-10.4f": "e8a614ace39650e743d2a4c4641c751eb958276215e2d68983c90a6cbc50fe47",
    "51xx.bin": "bd1c1fddde888550611fdb4ae29bc06d8ac2d2c6a2771ebbff243ec109caf26e",
    "54xx.bin": "85c8570b91342ab729bd775c500a3e7245d655a0bab2fed6356e37ea388848e8",
    "prom-1.1d": "079f5fd72fc52bfa9354927ecea9aaba240b1527f1a5951ee15975286b166b3b",
    "prom-2.5c": "8c34002652e587aa19a77bff9040d870af18b4b2fe5c5f0ed962899386e0e751",
    "prom-3.1c": "a3e80d099f7bcbfdd9a64239bda2e5e916c696d5dfb9294053bae57c46e184b1",
    "prom-4.2n": "6534ac170c6a8b0f567179bb4f24d4ab8337e3561e5f229a7bd9b128d29fed4f",
    "prom-5.5n": "5c2d0637794badb9a214324da3fd9ebbcd282a5c0f3a778fe6219fdba1c3b91a"
}



# Galaga Namco Rev A

NAMCO_REVA_FILES = [
    "gg1_1b.3p","gg1_2b.3m","gg1_3.2m","gg1_4b.2l",                                 # rom1 - CPU1
    "gg1_5b.3f",                                                                    # rom2 - SUBCPU
    "gg1_7b.2c",                                                                    # rom3 - SNDCPU
    "gg1_9.4l",                                                                     # GFX1
    "gg1_11.4d","gg1_10.4f",                                                        # GFX2
    "prom-1.1d", "prom-2.5c", "prom-3.1c", "prom-4.2n", "prom-5.5n",                # spr lookup, char lookup, palette proms
    "51xx.bin", "54xx.bin"                                                          # mcus
]



NAMCO_REVA_CHK = {
    
    "gg1_1b.3p": "9ade02d66a82d9de7bc890abc035baf4b386ef4f70a600f66f6f5276d6cbb82e",
    "gg1_2b.3m": "1525f3ef532df040720e8a21accd3930bab94f807d0b873932e150c4c3d0fdde",
    "gg1_3.2m": "4b0e52ec925d0db9232104bb728f68f2c3969bd125f75f100c4e59bb6780edff",
    "gg1_4b.2l": "7c7f796872e1c0e70be2c07e0a1c40b3f1d3a21bcd7018632700a98d29087064",
    "gg1_5b.3f": "a0b63c7983009606a19b7c2e48697a0f48669f977a1a6c21d5ae86f9d96b2620",
    "gg1_7b.2c": "f6b24ea6d3ece28350763f5f5550a1024d0ca23b9b85e5772994ab0558c8cdc1",
    "gg1_9.4l": "5e68d9567938d80ebba91168f511b1952dba19658a841b73811c947fd6649f98",
    "gg1_11.4d": "550119a20c3d9240bccefb6a0af2c3d00d3748dad7596bc8bab3c641126a53b7",
    "gg1_10.4f": "e8a614ace39650e743d2a4c4641c751eb958276215e2d68983c90a6cbc50fe47",
    "51xx.bin": "bd1c1fddde888550611fdb4ae29bc06d8ac2d2c6a2771ebbff243ec109caf26e",
    "54xx.bin": "85c8570b91342ab729bd775c500a3e7245d655a0bab2fed6356e37ea388848e8",
    "prom-1.1d": "079f5fd72fc52bfa9354927ecea9aaba240b1527f1a5951ee15975286b166b3b",
    "prom-2.5c": "8c34002652e587aa19a77bff9040d870af18b4b2fe5c5f0ed962899386e0e751",
    "prom-3.1c": "a3e80d099f7bcbfdd9a64239bda2e5e916c696d5dfb9294053bae57c46e184b1",
    "prom-4.2n": "6534ac170c6a8b0f567179bb4f24d4ab8337e3561e5f229a7bd9b128d29fed4f",
    "prom-5.5n": "5c2d0637794badb9a214324da3fd9ebbcd282a5c0f3a778fe6219fdba1c3b91a"
}


# Galaga Namco Rev B

NAMCO_REVB_FILES = [
    "gg1-1.3p","gg1-2.3m","gg1-3.2m","gg1-4.2l",                                    # rom1 - CPU1
    "gg1-5.3f",                                                                     # rom2 - SUBCPU
    "gg1-7.2c",                                                                     # rom3 - SNDCPU
    "gg1-9.4l",                                                                     # GFX1
    "gg1-11.4d","gg1-10.4f",                                                        # GFX2
    "prom-1.1d", "prom-2.5c", "prom-3.1c", "prom-4.2n", "prom-5.5n",                # spr lookup, char lookup, palette proms
    "51xx.bin", "54xx.bin"                                                          # mcus
]


NAMCO_REVB_CHK = {
    
    "gg1-1.3p": "73026995ac1a42b84b4eaf13ac9d42a6d8ad7e743f7688aff05f000cef6b581d",
    "gg1-2.3m": "0f30de5c8a68a91a5310b58c8098d89e98b441b964ae5d4f6bae282519bf4a86",
    "gg1-3.2m": "4b0e52ec925d0db9232104bb728f68f2c3969bd125f75f100c4e59bb6780edff",
    "gg1-4.2l": "588bd9df34eca91edc8e2f83dc5809d88ef0be8aee109241e46303f71901e6c0",
    "gg1-5.3f": "8f1c227ab936b82fb62dc010bec01779c09e192afab48f53542b629f51da1c8d",
    "gg1-7.2c": "1f22865adbd9c8657fdef4bb0b7e4de69df4e14d69b7f6583260c907d6b4e0ce",
    "gg1-9.4l": "5e68d9567938d80ebba91168f511b1952dba19658a841b73811c947fd6649f98",
    "gg1-11.4d": "550119a20c3d9240bccefb6a0af2c3d00d3748dad7596bc8bab3c641126a53b7",
    "gg1-10.4f": "e8a614ace39650e743d2a4c4641c751eb958276215e2d68983c90a6cbc50fe47",
    "51xx.bin": "bd1c1fddde888550611fdb4ae29bc06d8ac2d2c6a2771ebbff243ec109caf26e",
    "54xx.bin": "85c8570b91342ab729bd775c500a3e7245d655a0bab2fed6356e37ea388848e8",
    "prom-1.1d": "079f5fd72fc52bfa9354927ecea9aaba240b1527f1a5951ee15975286b166b3b",
    "prom-2.5c": "8c34002652e587aa19a77bff9040d870af18b4b2fe5c5f0ed962899386e0e751",
    "prom-3.1c": "a3e80d099f7bcbfdd9a64239bda2e5e916c696d5dfb9294053bae57c46e184b1",
    "prom-4.2n": "6534ac170c6a8b0f567179bb4f24d4ab8337e3561e5f229a7bd9b128d29fed4f",
    "prom-5.5n": "5c2d0637794badb9a214324da3fd9ebbcd282a5c0f3a778fe6219fdba1c3b91a"
}





def calculate_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def verify_checksums(temp_path,EXPECTED_CHKSM,EXPECTED_FILES):
    for file in EXPECTED_FILES:
        file_path = os.path.join(temp_path, file)
        calculated_checksum = calculate_sha256(file_path)
        expected_checksum = EXPECTED_CHKSM[file]
        if calculated_checksum != expected_checksum:
            print(f"Error: Checksum mismatch for {file}")
            print(f"Expected: {expected_checksum}")
            print(f"Calculated: {calculated_checksum}")
            sys.exit(1)

def main():

    # set pointer to particular version of Galaga.
    EXPECTED_FILES = ""
    EXPECTED_CHKSM = {}
    
    print("Galaga for MEGA65: ROM Installer")
    print("================================\n")
    if len(sys.argv) != 3:
        print("The Galaga core expects the files generated by this script located in the folder /arcade/galaga on your SD card.")
        print("This script supports the following versions of Galaga.\n")
        print("galaga         Galaga (Namco rev. B)                       (Namco, 1981)")
        print("galagao        Galaga (Namco)                              (Namco, 1981)")
        print("galagamk       Galaga (Midway set 2)                       (Namco (Midway license), 1981)")
        print("galagamw       Galaga (Midway set 1)                       (Namco (Midway license), 1981)")
        print("galagamf       Galaga (Midway set 1 with fast shoot hack)  (Namco (Midway license), 1981)\n")
        print("For example, To run Middway Set 1\n")
        print("Download this ZIP file from : https://wowroms.com/en/roms/mame-0.139u1/galaga-midway-set-1/3707.html")
        print("Or search the web for: mame galaga midway set 1\n")
        print("Usage: script.py <path to the zip file> <output_folder>")
        sys.exit(1)

    if len(sys.argv) > 1:
        argument_value = sys.argv[1]
        fileName = os.path.split(argument_value)[1]
        if fileName == "galagamw.zip":     # Galaga Midway set 1
            EXPECTED_FILES=MIDWAY_SET1_FILES
            EXPECTED_CHKSM=MIDWAY_SET1_CHK
        elif fileName == "galagamk.zip":                    # Galaga Midway set 2
            EXPECTED_FILES=MIDWAY_SET2_FILES
            EXPECTED_CHKSM=MIDWAY_SET2_CHK
        elif fileName == "galagamf.zip":                    # Galaga Midway set 1 with fast shoot hack
            EXPECTED_FILES=MIDWAYFS_SET1_FILES
            EXPECTED_CHKSM=MIDWAYFS_SET1_CHK
        elif fileName == "galaga.zip":                      # Galaga Namco  rev a
            EXPECTED_FILES=NAMCO_REVA_FILES
            EXPECTED_CHKSM=NAMCO_REVA_CHK
        elif fileName == "galagao.zip":                     # Galaga Namco  rev b
            EXPECTED_FILES=NAMCO_REVB_FILES
            EXPECTED_CHKSM=NAMCO_REVB_CHK
        else:
            print ("No match found for",sys.argv[1],"\n")
            print ("Suitable roms are galagamw.zip, galagamk.zip, galagamf.zip, galaga.zip & galagao.zip\n")
            return
    

    rom_zip_path = sys.argv[1]
    output_folder = sys.argv[2]

    if not os.path.exists(output_folder):
        print(f"Creating output folder: {output_folder}")
        os.makedirs(output_folder)

    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"Extracting files to temporary directory: {temp_dir}")
        try:
            with zipfile.ZipFile(rom_zip_path, 'r') as zip_ref:
                zip_ref.extractall(temp_dir)
                missing_files = [f for f in EXPECTED_FILES if not os.path.isfile(os.path.join(temp_dir, f))]
                if missing_files:
                    print(f"Error: Missing files in the provided zip file: {', '.join(missing_files)}")
                    sys.exit(1)

                print("Verifying checksums...")
                verify_checksums(temp_dir,EXPECTED_CHKSM,EXPECTED_FILES)

                # rom1
                print("Merging files and copying to output folder...")
                with open(os.path.join(output_folder, "rom1.rom"), "wb") as rom1:
                    for part in [EXPECTED_FILES[0], EXPECTED_FILES[1], EXPECTED_FILES[2], EXPECTED_FILES[3]]: 
                        print(f"Appending {part} to rom1.rom")
                        with open(os.path.join(temp_dir, part), "rb") as f:
                            rom1.write(f.read())
                            
                # rom2
                with open(os.path.join(output_folder, "rom2.rom"), "wb") as rom2:
                    for part in [EXPECTED_FILES[4]]: 
                        print(f"Copying {part} to rom2.rom")
                        with open(os.path.join(temp_dir, part), "rb") as f:
                            rom2.write(f.read())
                            
                 # rom3
                with open(os.path.join(output_folder, "rom3.rom"), "wb") as rom3:
                    for part in [EXPECTED_FILES[5]]: 
                        print(f"Copying {part} to rom3.rom")
                        with open(os.path.join(temp_dir, part), "rb") as f:
                            rom3.write(f.read())
  
                with open(os.path.join(output_folder, "gfx1.rom"), "wb") as gfx1:
                    for part in [EXPECTED_FILES[6], EXPECTED_FILES[6]]:
                        print(f"Appending {part} to gfx1.rom")
                        with open(os.path.join(temp_dir, part), "rb") as f:
                            gfx1.write(f.read())

                with open(os.path.join(output_folder, "gfx2.rom"), "wb") as gfx2:
                    for part in [EXPECTED_FILES[7], EXPECTED_FILES[8]]:
                        print(f"Appending {part} to gfx2.rom")
                        with open(os.path.join(temp_dir, part), "rb") as f:
                            gfx2.write(f.read())

                for filename in [EXPECTED_FILES[9], EXPECTED_FILES[10],
                                 EXPECTED_FILES[11], EXPECTED_FILES[12],EXPECTED_FILES[13], EXPECTED_FILES[14], EXPECTED_FILES[15]]:
                    print(f"Copying {filename} to output folder")
                    shutil.copy(os.path.join(temp_dir, filename), output_folder)

                print("Files extracted and merged successfully.")
                print("Cleaning up temporary files...")

        except FileNotFoundError:
            print(f"Error: ZIP file not found: {rom_zip_path}")
            sys.exit(1)
        except zipfile.BadZipFile:
            print(f"Error: Invalid or corrupted ZIP file: {rom_zip_path}")
            sys.exit(1)

if __name__ == "__main__":
    main()
