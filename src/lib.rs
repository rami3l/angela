#![forbid(unsafe_code)]
#![warn(
    clippy::pedantic,
    missing_copy_implementations,
    missing_debug_implementations,
    // missing_docs,
    rustdoc::broken_intra_doc_links,
    trivial_numeric_casts,
    unused_allocation
)]
// TODO: Remove the whitelist below.
#![allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]

pub(crate) mod bot;
pub(crate) mod cmd;

pub use crate::cmd::Angela;
