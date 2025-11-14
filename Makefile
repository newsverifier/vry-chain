build:
	cargo build --release
	cp target/release/vryd .

clean:
	cargo clean
	rm -f vryd
